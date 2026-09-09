# Cross-model MXINT and SF sparse results

Common scope: WikiText-2 test, 64 x 2,048 tokens, group size 32, E8M0 ceil, SF block size 32, K32/K40. MXINT4 includes Attention Hadamard; MXINT8 does not.

K is the Top-K budget of SF block selection: the number of 32-token key blocks kept for each query block, including the forced first and diagonal blocks. A 2,048-token sequence has 64 key blocks. The achieved block sparsity of every run is recorded in the `*_block_sparsity_percent` columns of `model_summary.csv`.

| Model | BF16 | INT8 dense | INT8 K32 | INT8 K40 | INT4+H dense | INT4+H K32 | INT4+H K40 |
|---|---:|---:|---:|---:|---:|---:|---:|
| qwen3_1_7b | 16.1065 | 16.0413 | 16.8810 | 16.3919 | 636.0407 | 649.9688 | 637.9022 |
| qwen3_4b | 12.9830 | 12.9483 | 13.4238 | 13.1423 | 28.5642 | 30.3095 | 29.2072 |
| qwen3_8b | 9.3570 | 9.3247 | 9.6261 | 9.4350 | 15.8701 | 17.0384 | 16.3009 |
| llama3_2_1b | 9.5083 | 9.5369 | 10.4889 | 9.9815 | 93.4953 | 105.4091 | 99.5109 |
| smollm2_1_7b | 7.9880 | 8.0209 | 8.6111 | 8.2592 | 27.1740 | 29.9172 | 28.3302 |
| llama3_2_3b | 7.6435 | 7.6591 | 8.0933 | 7.8129 | 15.7930 | 16.9102 | 16.1733 |
| llama2_7b | 5.5311 | 5.5376 | 6.4928 | 5.7998 | 7.5445 | 12.9678 | 9.4660 |
| mistral_7b | 5.2958 | 5.2984 | 5.5052 | 5.3682 | 7.7471 | 7.7741 | 7.6699 |
| pythia_6_9b | 10.3036 | 11.2634 | 11.8044 | 11.4914 | 202.6101 | 219.4415 | 207.4387 |
| gemma3_1b | 14.1433 | 14.2905 | 14.9209 | 14.5681 | 69.3699 | 74.6491 | 71.4550 |
| phi2_2_7b | 9.4702 | 9.5288 | 9.8271 | 9.6492 | 19.7907 | 21.3303 | 20.5848 |

See `data/README.md` for units, provenance, and interpretation.
