#include <iostream>
#include <string>
#include <cstdio>
#include <stdint.h>

#include "TFile.h"
#include "TTree.h"

#include "THaCodaFile.h"


#include "fa250types.h"
#include "jlabtypes.h"

int current_chan = 0;
int entry = 0;
int data_a[16][250];


void decode_word(uint32_t data)
{
    static uint32_t type_last = 15;	/* initialize to type FILLER WORD */
    static uint32_t time_last = 0;
    static int new_type = 0;
    int type_current = 0;
    static int pulse_number = 0;
    static int isca = 0;
    generic_data_word_t gword;

    gword.raw = data;

    if(gword.bf.data_type_defining) /* data type defining word */
    {
        new_type = 1;
        type_current = gword.bf.data_type_tag;
    }
    else
    {
        new_type = 0;
        type_current = type_last;
    }

    switch( type_current )
    {
        case 0:		/* BLOCK HEADER */
            {
                if( new_type )
                {
                    block_header_t d; d.raw = data;
                }
                else
                {
                    fa250_block_header_2_t d; d.raw = data;
                }
                break;
            }

        case 1:		/* BLOCK TRAILER */
            {
                block_trailer_t d; d.raw = data;
                break;
            }

        case 2:		/* EVENT HEADER */
            {
                fa250_event_header_t d; d.raw = data;
                break;
            }

        case 3:		/* TRIGGER TIME */
            {
                if( new_type )
                {
                    fa250_trigger_time_1_t d; d.raw = data;
                    time_last = 1;
                }
                else
                {
                    fa250_trigger_time_2_t d; d.raw = data;
                    if( time_last == 1 )
                    {
                        // std::printf("%8X - TRIGGER TIME 2 - time = %08x\n",
                        //        d.raw,
                        //        (d.bf.T_A<<16) | (d.bf.T_B<<8) | (d.bf.T_C) );
                    }
                    else
                        //   std::printf("%8X - TRIGGER TIME - (ERROR)\n", data);

                        time_last = 0;
                }
                break;
            }

        case 4:		/* WINDOW RAW DATA */
            {
                if( new_type )
                {
                    fa250_window_raw_data_1_t d; d.raw = data;
                    current_chan = d.bf.channel_number;
                    entry = 0;
                }
                else
                {
                    fa250_window_raw_data_n_t d; d.raw = data;
                    data_a[current_chan][entry++] = d.bf.adc_sample_1;
                    data_a[current_chan][entry++] = d.bf.adc_sample_2;
                }
                break;
            }

        case 5:		/* PEPPo Channel Sums */
            {
                if( new_type )
                {
                    fa250_peppo_hi_sum_t d; d.raw = data;
                    break;
                }
                else
                {
                    fa250_peppo_lo_sum_t d; d.raw = data;
                    std::printf("%8X - PEPPo Lo Sum - lo sum = 0x%06x\n", d.raw, d.bf.lo_sum);
                    break;
                }
            }

        case 7:		/* PULSE INTEGRAL */
            {
                fa250_pulse_integral_t d; d.raw = data;
                break;
            }

        case 8:		/* PULSE TIME */
            {
                fa250_pulse_time_t d; d.raw = data;
                break;
            }

        case 9:		/* PULSE PARAMETERS */
            {
                if( new_type )
                { /* Channel ID and Pedestal Info */
                    fa250_pulse_parameters_1_t d; d.raw = data;
                    pulse_number  = 0; /* Initialize */
                }
                else
                {
                    if(data & (1<<30))
                    { /* Word 1: Integral of n-th pulse in window */
                        fa250_pulse_parameters_2_t d; d.raw = data;
                        pulse_number++;
                    }
                    else
                    { /* Word 2: Time of n-th pulse in window */
                        fa250_pulse_parameters_3_t d; d.raw = data;
                    }
                }

                break;
            }

        case 12:		/* SCALER HEADER */
            if( new_type )
            {
                fa250_scaler_1_t d; d.raw = data;
                isca = 1;
            }
            break;

        case 13:		/* END OF EVENT */
            {
                event_trailer_t d; d.raw = data;
                break;
            }

        case 14:		/* DATA NOT VALID (no data available) */
            {
                data_not_valid_t d; d.raw = data;
                break;
            }

        case 15:		/* FILLER WORD */
            {
                filler_word_t d; d.raw = data;
                break;
            }
    }

    type_last = type_current;	/* save type of current data word */

}

void decode_fadc(std::string inputfile, std::string outputfile)
{
    Decoder::THaCodaFile f(inputfile.c_str());

    TFile *file = new TFile(outputfile.c_str(), "RECREATE");

    UInt_t * buf;
    //std::string chan = "channel7";

    TTree *tree = new TTree("tree", "Decoded Data Tree");

    // Create branches for each channel
    std::vector<TBranch*> branches;
    for (size_t i = 0; i < 16; ++i) {
        std::string branchName = "channel" + std::to_string(i);
        TBranch *branch = tree->Branch(branchName.c_str(), &data_a[i], "data_a[250]/I", 40000);
        branches.push_back(branch);
    }

    buf = f.getEvBuffer();
    f.codaRead();
    buf = f.getEvBuffer();
    f.codaRead();

    int t = 1;

    while (f.codaRead()==0){
        buf = f.getEvBuffer();
        int size = f.getBuffSize();

        // Fill the array with data
        for (int i = 0; i < size; ++i) {
            decode_word(buf[i]);
        }

        tree->Fill();
        t++;

    }

    // Write the tree to the file and close it
    tree->Write();
    file->Close();
    std::cout<<outputfile<<" written"<<std::endl;
}

