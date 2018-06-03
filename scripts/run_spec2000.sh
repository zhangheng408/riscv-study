#!/bin/sh

#The test cmd is from Spec2000/benchspec/CINT2000/testcase/Spec/object.pm

specDIR=/spec2000

echo -n "run 164.gzip ..."
${specDIR}/164.gzip/gzip_base.mprc ${specDIR}/164.gzip/input.compressed 2 > ${specDIR}/164.gzip/gzip.compressed.out 2>> ${specDIR}/164.gzip/gzip.compressed.err
diff ${specDIR}/164.gzip/gzip.compressed.out ${specDIR}/164.gzip/gzip.compressed.out.ref > /dev/null
if [ $? == 0 ]; then echo "success"; else echo "fail"; fi

echo -n "run 175.vpr place ..."
cd ${specDIR}/175.vpr/
${specDIR}/175.vpr/vpr_base.mprc net.in arch.in place.out dum.out -nodisp -place_only -init_t 5 -exit_t 0.005 -alpha_t 0.9412 -inner_num 2 > ${specDIR}/175.vpr/place_log.out 2>> ${specDIR}/175.vpr/place_log.err
diff ${specDIR}/175.vpr/place_log.out ${specDIR}/175.vpr/place_log.out.ref > /dev/null
if [ $? == 0 ]; then echo "success"; else echo "fail"; fi

echo -n "run 175.vpr route ..."
cd ${specDIR}/175.vpr/
${specDIR}/175.vpr/vpr_base.mprc net.in arch.in place.in route.out -nodisp -route_only -route_chan_width 15 -pres_fac_mult 2 -acc_fac 1 -first_iter_pres_fac 4 -initial_pres_fac 8 > ${specDIR}/175.vpr/route_log.out 2>> ${specDIR}/175.vpr/route_log.err
diff ${specDIR}/175.vpr/route.out ${specDIR}/175.vpr/route.out.ref > /dev/null
if [ $? == 0 ]; then echo "success"; else echo "fail"; fi

echo -n "run 176.gcc ..."
${specDIR}/176.gcc/cc1_base.mprc ${specDIR}/176.gcc/cccp.i -o ${specDIR}/176.gcc/cccp.s >${specDIR}/176.gcc/cccp.out 2>> ${specDIR}/176.gcc/cccp.err
diff ${specDIR}/176.gcc/cccp.s ${specDIR}/176.gcc/cccp.s.ref > /dev/null
if [ $? == 0 ]; then echo "success"; else echo "fail"; fi

echo -n "run 181.mcf ..."
${specDIR}/181.mcf/mcf_base.mprc ${specDIR}/181.mcf/inp.in >${specDIR}/181.mcf/inp.out 2>> ${specDIR}/181.mcf/inp.err
diff ${specDIR}/181.mcf/inp.out ${specDIR}/181.mcf/inp.out.ref > /dev/null
if [ $? == 0 ]; then echo "success"; else echo "fail"; fi

echo -n "run 186.crafty ..."
${specDIR}/186.crafty/crafty_base.mprc < ${specDIR}/186.crafty/crafty.in > ${specDIR}/186.crafty/crafty.out 2>> ${specDIR}/186.crafty/crafty.err
diff ${specDIR}/186.crafty/crafty.out ${specDIR}/186.crafty/crafty.out.ref > /dev/null
if [ $? == 0 ]; then echo "success"; else echo "fail"; fi

echo -n "run 197.parser ..."
cd ${specDIR}/197.parser
${specDIR}/197.parser/parser_base.mprc ${specDIR}/197.parser/2.1.dict -batch < ${specDIR}/197.parser/test.in > ${specDIR}/197.parser/test.out 2>> ${specDIR}/197.parser/test.err
diff ${specDIR}/197.parser/test.out ${specDIR}/197.parser/test.out.ref > /dev/null
if [ $? == 0 ]; then echo "success"; else echo "fail"; fi

#echo -n "run 252.eon cook.."
#cd ${specDIR}/252.eon
#${specDIR}/252.eon/eon_base.mprc chair.control.cook chair.camera chair.surfaces chair.cook.ppm ppm pixels_out.cook > cook_log.out 2>> cook_log.err
#diff ${specDIR}/252.eon/pixels_out.cook ${specDIR}/252.eon/pixels_out.cook.ref > /dev/null
#if [ $? == 0 ]; then echo "success"; else echo "fail"; fi
#
#echo -n "run 252.eon rushmeier ..."
#cd ${specDIR}/252.eon
#${specDIR}/252.eon/eon_base.mprc chair.control.rushmeier chair.camera chair.surfaces chair.rushmeier.ppm ppm pixels_out.rushmeier > rushmeier_log.out 2>> rushmeier_log.err
#diff ${specDIR}/252.eon/pixels_out.rushmeier ${specDIR}/252.eon/pixels_out.rushmeier.ref > /dev/null
#if [ $? == 0 ]; then echo "success"; else echo "fail"; fi
#
#echo -n "run 252.eon kajiya ..."
#cd ${specDIR}/252.eon
#${specDIR}/252.eon/eon_base.mprc chair.control.kajiya chair.camera chair.surfaces chair.kajiya.ppm ppm pixels_out.kajiya > kajiya_log.out 2>> kajiya_log.err
#diff ${specDIR}/252.eon/pixels_out.kajiya ${specDIR}/252.eon/pixels_out.kajiya.ref > /dev/null
#if [ $? == 0 ]; then echo "success"; else echo "fail"; fi
#
#echo -n "run 254.gap ..."
#cd ${specDIR}/254.gap
#${specDIR}/254.gap/gap_base.mprc -l ./ -q -m 64M < ${specDIR}/254.gap/test.in > ${specDIR}/254.gap/test.out 2>> ${specDIR}/254.gap/test.err
#diff ${specDIR}/254.gap/test.out ${specDIR}/254.gap/test.out.ref > /dev/null
#if [ $? == 0 ]; then echo "success"; else echo "fail"; fi

echo -n "run 255.vortex ..."
cd ${specDIR}/255.vortex
${specDIR}/255.vortex/vortex_base.mprc lendian.raw > ${specDIR}/255.vortex/vortex.out 2>>${specDIR}/255.vortex/vortex.err
diff ${specDIR}/255.vortex/vortex.out ${specDIR}/255.vortex/vortex.out.ref > /dev/null
if [ $? == 0 ]; then echo "success"; else echo "fail"; fi

echo -n "run 256.bzip2 ..."
${specDIR}/256.bzip2/bzip2_base.mprc ${specDIR}/256.bzip2/input.random 2 > ${specDIR}/256.bzip2/input.random.out 2>>${specDIR}/256.bzip2/input.random.err
diff ${specDIR}/256.bzip2/input.random.out ${specDIR}/256.bzip2/input.random.out.ref > /dev/null
if [ $? == 0 ]; then echo "success"; else echo "fail"; fi

echo -n "run 300.twolf ..."
cd ${specDIR}/300.twolf
${specDIR}/300.twolf/twolf_base.mprc test > ${specDIR}/300.twolf/test.stdout 2>>${specDIR}/300.twolf/twolf.err
diff ${specDIR}/300.twolf/test.stdout ${specDIR}/300.twolf/test.stdout.ref > /dev/null
if [ $? == 0 ]; then echo "success"; else echo "fail"; fi
