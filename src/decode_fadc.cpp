#include <iostream>
#include <string>
#include <cstdio>
#include <stdint.h>

#include "TFile.h"
#include "TTree.h"

#include "THaCodaFile.h"

#include "eviotypes.h"

int current_chan = 0;
int entry = 0;
int data_a[16][250];


void decode_word(uint32_t data)
{
    static uint32_t type_last = 15;	/* initialize to type FILLER WORD */
    static int new_type = 0;
    int type_current = 0;
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
        case 4:		/* WINDOW RAW DATA */
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

    type_last = type_current;	/* save type of current data word */

}

void decode_fadc(std::string inputfile, std::string outputfile)
{
    Decoder::THaCodaFile f(inputfile.c_str());

    TFile *file = new TFile(outputfile.c_str(), "RECREATE");


    TTree *tree = new TTree("tree", "Decoded Data Tree");

    // Create branches for each channel
    std::vector<TBranch*> branches;
    for (size_t i = 0; i < 16; ++i) {
        std::string branchName = "channel" + std::to_string(i);
        TBranch *branch = tree->Branch(branchName.c_str(), &data_a[i], "data_a[250]/I", 40000);
        branches.push_back(branch);
    }

    UInt_t * buf;
    buf = f.getEvBuffer(); f.codaRead(); // ignore two blocks
    buf = f.getEvBuffer(); f.codaRead(); // ignore two blocks

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

    tree->Write();
    file->Close();
    std::cout<<"Written "<<t<<" events to:"<<outputfile<<std::endl;
}

