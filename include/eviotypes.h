#ifndef __EVIOTYPES__
#define __EVIOTYPES__
#include <stdint.h>

typedef struct
{
  uint32_t undef:27;
  uint32_t data_type_tag:4;
  uint32_t data_type_defining:1;
} generic_data_word;

typedef union
{
  uint32_t raw;
  generic_data_word bf;
} generic_data_word_t;

typedef struct
{
  uint32_t PTW:9;
  uint32_t undef:14;
  uint32_t channel_number:4;
  uint32_t data_type_tag:4;
  uint32_t data_type_defining:1;
} fa250_window_raw_data_1;

typedef union
{
  uint32_t raw;
  fa250_window_raw_data_1 bf;
} fa250_window_raw_data_1_t;

typedef struct
{
  uint32_t adc_sample_2:13;
  uint32_t invalid_2:1;
  uint32_t undef2:2;
  uint32_t adc_sample_1:13;
  uint32_t invalid_1:1;
  uint32_t undef1:1;
  uint32_t data_type_defining:1;
} fa250_window_raw_data_n;

typedef union
{
  uint32_t raw;
  fa250_window_raw_data_n bf;
} fa250_window_raw_data_n_t;


#endif /* __EVIOTYPES__ */
