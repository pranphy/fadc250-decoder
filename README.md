# FADC250 Decoder

This decodes evio files produced by CODA for the FADC250 ADC at JLab. It uses evio header to read the data and convert to root format. This should be adaptable to do any other FADC250 interfaced with coda, but it was specifically tested for EEL 112 lab.


## Dependencies

   - EVIO: The project depends evio library. The evio library is available at [Github Repository](https://github.com/JeffersonLab/evio). If you are going to be using this decoder in the ifarm HPC then the library is already compiled and available in the farm nodes. Just Just
        ```bash
        module load evio
        ```
        This should set environment variable `EVIO` which is what the build file of this project looks for the evio header and `libevio.so`.
        On your local machine you need to compile the [evio library](https://github.com/JeffersonLab/evio) first. And set the environment variable `EVIO` to the path to the evio library.
   - ROOT: ROOT is a dependency because we are producing root file. At ifarm `root` should already be available. Specifically the build file uses `root-config` executable to look for the include and library path.



## Build Instructions

This project is built using `make` and comes with a `Makefile`.

To build the project, you will need the following:

*   A C++ compiler (e.g., GCC, Clang)
*   make

Follow these steps to build the project:

1.  Clone the repository:

    ```bash
    git clone https://github.com/pranphyfadc250-decoder/
    ```

2.  Build the project:

    ```bash
    make 
    ```
    This will produce an executable named `decoder` in the `bin` directory.

## Usage Instructions

To use the decoder, run the following command:

```bash
./bin/decoder <input_file.evio> <output_file.root>
```

where `<input_file>` is the path to the FADC250 data file and `<output_file>` is the path to the output file.

> [!IMPORTANT]
> This resulting executable depends upon the dynamic evio library `libevio.so`, make sure that `libevio.so` is in the `LD_LIBRARY_PATH` environment variable. Again, on ifarm `module load evio` should take care of this.

## Output Tree
The output tree is named "tree" and has branches corresponding to each of the ADC channels, for example `channel5` for the 5th channel (0 based index). Each entry in the branch is an event.


