#ifndef DECODE_FADC_H
#define DECODE_FADC_H

#include <string>
#include <stdint.h>

void decode_word(uint32_t data);
void decode_fadc(std::string inputfile, std::string outputfile);

#endif
