# Set the working directory
set work_dir "work"
set src_dir "../src"
set tb_dir "../tb"


# Remove all files in the simulation directory except the current script
# if {[file exists $sim_dir]} {
#     foreach file [glob -nocomplain "$sim_dir/*"] {
#         if {$file != $this_script} {
#             file delete -force $file
#         }
#     }
# } else {
#     file mkdir $sim_dir
# }

# Create the work library if it does not exist
if {[file exists $work_dir]} {
    vdel -lib $work_dir -all
}
vlib $work_dir

# Compile the design files
vmap work $work_dir

# List of RTL files to compile
set rtl_files {
    constants.vhd
    iv.vhd
    nd2.vhd
    fa.vhd
    encoder.vhd
    mux21_generic.vhd
    mux51_generic.vhd
    rcaN.vhd    
    cs_generic.vhd
    G_block.vhd
    PG_block.vhd
    PG_network.vhd
    sum_gen_generic.vhd
    carry_generator.vhd
    p4_adder.vhd
    BOOTHMUL.vhd
}

# Compile each RTL file
foreach file $rtl_files {
    vcom -work work "$src_dir/$file"
}

# Compile the testbench
vcom -work work "$tb_dir/tb_multiplier.vhd"

# Load the testbench
vsim -voptargs="+acc" work.tb_multiplier

#adding waves
add wave *

run 1000ns
