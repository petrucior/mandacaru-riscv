BOARD=tangnano9k
FAMILY=GW1N-9C
DEVICE=GW1NR-LV9QN88PC6/I5
FILE=risc
FILES=datapath.v control.v

all:	$(FILE).fs

# Synthesis
$(FILE).json: $(FILE).v $(FILES)
	yosys -p "read_verilog $(FILE).v $(FILES); synth_gowin -top $(FILE); write_json $(FILE).json"

# Place and Route
$(FILE)_pnr.json: $(FILE).json
	nextpnr-himbaechel --json $(FILE).json --write $(FILE)_pnr.json --freq 27 --device ${DEVICE} --vopt family=${FAMILY} --vopt cst=${BOARD}.cst
	#nextpnr-gowin --json $(FILE).json --write $(FILE)_pnr.json --freq 27 --device ${DEVICE} --family ${FAMILY} --cst ${BOARD}.cst


# Generate Bitstream
$(FILE).fs: $(FILE)_pnr.json
	gowin_pack -d ${FAMILY} -o $(FILE).fs $(FILE)_pnr.json

# Program Board
loadflash: $(FILE).fs
	sudo openFPGALoader -b ${BOARD} $(FILE).fs -f

loadram: $(FILE).fs
	sudo openFPGALoader -b ${BOARD} $(FILE).fs -m

clean:
	rm *.json *.fs *~ 
