`ifndef MEM_H
`define MEM_H

`define VPN1_LENGTH 10
`define VPN0_LENGTH 10
`define PPN1_LENGTH 12
`define PPN0_LENGTH 10
`define PAGE_OFFSET 12

typedef struct packed {
    logic [`PPN1_LENGTH-1:0] PPN1;
    logic [`PPN0_LENGTH-1:0] PPN0;
    logic [1:0] RSW;
    logic D;
    logic A;
    logic G;
    logic U;
    logic X;
    logic W;
    logic R;
    logic V;
} page_entry_t;

typedef struct packed {
    logic [`VPN1_LENGTH-1:0] VPN1;
    logic [`VPN0_LENGTH-1:0] VPN0;
    logic [`PAGE_OFFSET-1:0] offset;
} virtual_address_t;

typedef struct packed {
    logic [`PPN1_LENGTH-1:0] PPN1;
    logic [`PPN0_LENGTH-1:0] PPN0;
    logic [`PAGE_OFFSET-1:0] offset;
} physical_address_t;

`define ASID_LENGTH 8

typedef struct packed {
    logic mode;
    logic [`ASID_LENGTH-1:0] asid;
    logic [`PPN1_LENGTH+`PPN0_LENGTH-1:0] ppn;
} satp_t;

`define TLBT_LENGTH 5
`define TLBI_LENGTH (32 - `TLBT_LENGTH - `PAGE_OFFSET)

typedef struct packed {
    logic [`TLBI_LENGTH-1:0] TLBI;
    logic [`TLBT_LENGTH-1:0] TLBT;
    logic [`PAGE_OFFSET-1:0] offset;
} tlb_req_t;

typedef struct packed {
    logic [`TLBI_LENGTH-1:0] TLBI;
    logic [`ASID_LENGTH-1:0] ASID; // not used temporary
    page_entry_t page;
    logic valid;
} tlb_entry_t;

`define MMU_OWN 0
`define TRANSLATE_OWN 1
`define CACHE_OWN 2
`endif