`define VPN1_LENGTH 10
`define VPN0_LENGTH 10
`define PPN1_LENGTH 12
`define PPN0_LENGTH 10
`define PAGE_OFFSET 12

typedef struct packed {
    logic [`PPN1_LENGTH-1:0] PPN1,
    logic [`PPN0_LENGTH-1:0] PPN0,
    logic [1:0] RSW,
    logic D,
    logic A,
    logic G,
    logic U,
    logic X,
    logic W,
    logic R,
    logic V
} page_entry_t;

typedef struct packed {
    logic [`VPN1_LENGTH-1:0] VPN1,
    logic [`VPN0_LENGTH-1:0] VPN0,
    logic [`PAGE_OFFSET-1:0] offset
} virtual_address_t;

typedef struct packed {
    logic [`PPN1_LENGTH-1:0] PPN1,
    logic [`PPN0_LENGTH-1:0] PPN0,
    logic [`PAGE_OFFSET-1:0] offset
} physical_address_t;

typedef struct packed {
    logic mode,
    logic [8:0] asid,
    logic [`PPN1_LENGTH+`PPN0_LENGTH-1:0] ppn
} satp_t;