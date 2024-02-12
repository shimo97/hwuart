vlib work
vdel -all
vlib work

vcom -93 -work ./work ../src/tx_block.vhd
vcom -93 -work ./work ../src/clk_gen.vhd

vlog -work ./work ../tb/tb_tx_block.v

vsim work.tb_rx_block -voptargs=+acc
add wave sim:/tb_rx_block/*
add wave sim:/tb_rx_block/DUT/STATE
add wave sim:/tb_rx_block/DUT/DATA
add wave sim:/tb_rx_block/DUT/S_VAL
add wave sim:/tb_rx_block/DUT/SMP_CNT
add wave sim:/tb_rx_block/DUT/DATA_CNT
add wave sim:/tb_rx_block/DUT/D_VAL
add wave sim:/tb_rx_block/DUT/LOAD_TX

run 5us
