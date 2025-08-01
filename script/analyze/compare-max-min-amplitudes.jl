using Format
using UnROOT
using LaTeXStrings
using GLMakie
using StatsBase
using Peaks
using LsqFit
using SpecialFunctions

set_theme!(merge(theme_latexfonts(),slide(30)))


function running_avg(sig;bins=5)
    av = []
    for i in 1:(length(sig)-bins)
        t = sum(sig[i:i+bins])
        push!(av,t)
    end
    (av .- av[1]) ./ bins
end

function get_all_peaks(signal)
    idxes = []; sigs = []
    yp = running_avg(signal; bins=5)
    indices,heights = findmaxima(yp) # findmaxima comes from the Peaks package.
    indices,proms = peakproms(indices,yp)
    indices, widths, edges... = peakwidths(indices,yp,proms)
    idx = (widths .> 2) .& (heights .> 21) # arbitrary value sort of trial and error
    ip = indices[idx]; hp = heights[idx]; wp = widths[idx];
    wd = ceil.(Int64,wp)
    for kk in 1:length(ip)
        wdi = wd[kk] + 2
        xr = ip[kk] - wdi+4:1:ip[kk]+wdi+4 # again going +- 4 is arbitrary
        csig = []
        try 
            csig = signal[xr]
            push!(idxes,xr); push!(sigs, signal[xr])
        catch
            # there are cases where the signal starts in fist bin. Ignore them they are malformed anyway.
            nothing
        end
    end
    return idxes,sigs
end

function get_photon_counts(signal)
    noise_floor = sum(signal[1:20])/20
    idxs,sigs = get_all_peaks(signal)
    sigsums = [sum(sig .- noise_floor) for sig in sigs]
    nums = ceil.(Int64, sigsums ./ minimum(sigsums))
end

function get_signal_events(channel_data)
    uv = []
    for event in 1 : length(channel_data)
        sig = channel_data[event]
        if maximum(sig) > 280 # 270 ish is noise floor. 10 safety net.
            push!(uv,event)
        end
    end
    uv
end

function get_single_photon_adci(signal,mmax)
    idxs, sigs = get_all_peaks(signal)
    noise_floor = ceil.(Int32,sum(signal[1:20])/20)
    adci = [sum(sig .- noise_floor) for sig in sigs]
    length(idxs) > 1 ? mmax(adci) : -1
end

function get_single_photon_adci_all(signal,mmax)
    idxs, sigs = get_all_peaks(signal)
    noise_floor = ceil.(Int32,sum(signal[1:20])/20)
    adci = [sum(sig .- noise_floor) for sig in sigs]
    mmax(adci)
end

function get_single_photon_amplitude(signal,argmmx)
    idxs, sigs = get_all_peaks(signal)
    noise_floor = ceil(Int32,sum(signal[1:20])/20)
    length(idxs) > 1 ?  maximum(sigs[argmmx([sum(sig) for sig in sigs])])-noise_floor : -1
end

function get_single_photon_integrals(channel_data,uv,mmax)
    itg = Vector{Int32}()
    for i in uv
        adci = get_single_photon_adci(channel_data[i],mmax)
        if adci > 0
            push!(itg, adci)
        end
    end
    itg
end

function get_single_photon_amplitudes(channel_data,uv,argmmx)
    #uv = get_signal_events(channel_data);
    amps = Vector{Int32}()
    for i in uv
        adca = get_single_photon_amplitude(channel_data[i],argmmx)
        if adca > 0
            push!(amps, adca)
        end
    end
    amps
end

function get_all_counts(channel_data,uv)
    pc = Vector{Int32}()
    for i in uv
        num_photons = get_photon_counts(channel_data[i])
        #num_photons = [3]
        if length(num_photons) > 1 
            pc = vcat(pc,num_photons)
        end
    end
    pc
end

function plot_peaks(ax,channel_data,num;count=true)
    y = channel_data[num]
    stairs!(ax,y,linewidth=3)
    idxs,sigs = get_all_peaks(y)
    nums = get_photon_counts(y)
    for i in 1:length(idxs)
        stairs!(ax,idxs[i],sigs[i],linewidth=3,label="Signal $(i)")#,linestyle=:dash)
        if count
            ixav = ceil(Int64,sum(idxs[i]) / length(idxs[i])); mv = y[ixav];
            tooltip!(ax,ixav,0.8*mv,"$(nums[i])",backgroundcolor=:pink)#,linestyle=:dash)
        end
    end
    axislegend(ax)
end

function poisson(lambda,A,k)
    y0 = exp(-abs(lambda))* abs(lambda) ^ k[1] / gamma(k[1] + 1)
    A*exp(-abs(lambda))* lambda .^ k ./ gamma.(k .+ 1)
end

pd(t,m) = poisson(m[1],m[2],t)

function normal(x,p)
    A,mu,sigma = p[1],p[2],p[3]
    return A*exp.(-(0.5*(x .- mu)/sigma) .^ 2)
end


function plot!(ax,h::Histogram)
    cts = h.weights
    if length(h.edges[1]) > length(h.weights) pushfirst!(cts,h.weights[1]) end
    stairs!(ax,h.edges[1],cts,linewidth=2)
end

function fit_func(h::Histogram,func,p)
    xv = h.edges[1]
    yv = h.weights
    if length(xv) > length(yv) pushfirst!(yv,yv[1]) end
    curve_fit(func,xv,yv,p)
end

function plot_signal(channel_data,num)
    fig = Figure(size=(800,600)); ax = Axis(fig[1,1],xlabel="Clock unit",ylabel="ADC Value (arb unit)",title="PMT Signal, Event number $(num)")
    stairs!(ax,channel_data[num],label="Signal",linewidth=2) # 3 18
    fig
end

function (@main)(args)
    filename0 = "../data/root/tst-110.root"

    f0 = ROOTFile(filename0)

    T0 = LazyTree(f0,"tree",["channel$(r)" for r in [2,11,13]])
    uv = get_signal_events(T0.channel13); # filters only the signal events.

    # make example plot to check
    plot_signal(T0.channel13,uv[15])


    # checking arbitrary signal, lets take 12 for now.
    idx = 12
    integral = get_single_photon_adci_all(T0.channel11[uv[idx]],maximum)
    plot_signal(T0.channel11,uv[idx])

    # Now that we know it works, lets  overlay multiple of these signals.

    fig = Figure(size=(800,600)); ax = Axis(fig[1,1],ylabel="ADC Values",xlabel="Time Unit")
    for n in 1:3
        try
            plot_peaks(ax,T0.channel13,uv[n]; count=false)
        catch
        end
    end
    save("../asset/image/at001/selection-of-peaks.png",fig)

    # for out PMT channel 13, lets plot maximum and minimum photon amplitudes.
    itgn = get_single_photon_integrals(T0.channel13,uv,minimum)
    itgx = get_single_photon_integrals(T0.channel13,uv,maximum)
    h1 = fit(Histogram, itgn, nbins=200)
    h2 = fit(Histogram, itgx ./1e4, nbins=200)

    fig = Figure(size=(1600,600)); 
    ax = Axis(fig[1,1],xlabel="Integral [Arb. Unit]",ylabel="Counts",title="One Photon Integral")
    ax2 = Axis(fig[1,2],xlabel=L"\text{Integral}( 1 \times 10^{4}) ",ylabel="Counts",title="Maximum Photon Integral")
    plot!(ax,h1)
    plot!(ax2,h2)
    save("../asset/image/at001/adci-integrals-minus-noise.png",fig)

    itgn = get_single_photon_integrals(T0.channel11,uv,minimum)
    itgx_trigger = get_single_photon_integrals(T0.channel11,uv,maximum)


    h1 = fit(Histogram, itgn ./1e4, nbins=200)
    h2 = fit(Histogram, itgx ./1e4, nbins=200)

    fig = Figure(size=(1600,600)); 
    ax = Axis(fig[1,1],xlabel="Integral [Arb. Unit]",ylabel="Counts",title="One Photon Integral Trigger")
    ax2 = Axis(fig[1,2],xlabel=L"\text{Integral}( 1 \times 10^{4}) ",ylabel="Counts",title="Maximum Photon Integral Trigger")
    plot!(ax,h1)
    plot!(ax2,h2)
    save("../asset/image/at001/adci-integrals-01.png",fig)

    # Lets see minimum signal and maximum signal from channel 13, which is where
    # we had our PMT signal.

    itgn = get_single_photon_amplitudes(T0.channel13,uv,argmin);
    itgx_signal = get_single_photon_amplitudes(T0.channel13,uv,argmax);

    h1 = fit(Histogram, itgn, nbins=200)
    h2 = fit(Histogram, itgx, nbins=200)
    cf1 = fit_func(h1,normal,[100,2000,1000.0]); ster1 = stderror(cf1)
    cf2 = fit_func(h2,normal,[100,2000,1000.0]); ster2 = stderror(cf2)
    xv1 = range(0,500,100); yv1 = normal(xv1,cf1.param)
    xv2 = range(0,4000,100); yv2 = normal(xv2,cf2.param)

    # Now plot the fitted functions.
    fig = Figure(size=(1600,600)); ax = Axis(fig[1,1],xlabel="Integral (Arb. Unit)",ylabel="Counts",title="One Photon Amplitude")
    ax2 = Axis(fig[1,2],xlabel="Integral (Arb. Unit)",ylabel="Counts",title="Maximum Photon Amplitude")

    lines!(ax,xv1,yv1,label=format("μ={:.2f} ± {:.2f}",cf1.param[2],ster1[2]),linestyle=:dash,color=:red)
    plot!(ax,h1)

    lines!(ax2,xv2,yv2,label=format("μ={:.2f} ± {:.2f}",cf2.param[2],ster2[2]),linestyle=:dash,color=:red)
    plot!(ax2,h2)
    axislegend(ax); axislegend(ax2)
    tooltip!(ax,500, 50, "Large Fiber")
    tooltip!(ax2,5000, 50, "Large Fiber")
    fig
    save("../asset/image/at001/adci-amplitudes-minus-noise-with-mu-large.png",fig)

end
