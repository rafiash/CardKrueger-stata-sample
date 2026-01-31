* This code is a replication of Card and Krueger's 1994 analysis of the effect of a minimum wage increase on fast food employment around the NJ/PA border. The data is from David Card's website. I replicated Figure 1 and Table 3 in their paper which use difference-in-difference regression to demonstrate that the minimum wage increase did not cause a relative drop in employment compared to Pennsylvania as a control case. To run the program, you can find the data and code at http://github.com/rafiash/CardKrueger-stata-sample/
* Card, David & Krueger, Alan B, 1994. "Minimum Wages and Employment: A Case Study of the Fast-Food Industry in New Jersey and Pennsylvania," American Economic Review, American Economic Association, vol. 84(4), pages 772-793, September.

clear all

capture log close
cd "C:\Users\16693\Downloads\Stata Sample\"
log using CardKruegerNJmw.log, replace
#delimit ;

* ssc install diff;
* ssc install bihist;

infile sheet chainr co_owned stater southj centralj northj pa_a pa_b shore
ncalls1 empft1 emppt1 nmgrs1 wage_st1 inctime1 firstinc1 bonus1 pctaff meals1
open1 hrsopen1 psoda1 pfry1 pentree1 nregs1 nregs11am1 type2 status2 date2
ncalls2 empft2 emppt2 nmgrs2 wage_st2 inctime2 firstinc2 special2
meals2 open2 hrsopen2 psoda2 pfry2 pentree2 nregs2 nregs11am2 using public.dat;
*renamed open2 from open2r, firstin2 --> firstinc2, appended a 1 to all pre-change variable names, renamed pa1 and pa2 to pa_a and pa_b to avoid confusion;

#delimit cr 

*warning: sheet 407 is used twice (once in NJ (1), once in PA (0) )
replace sheet = 408 if sheet == 407 & stater == 1

*fixing variable names
rename bonus1 special1
                                                                
summarize                                                                              
gen emptot1 = emppt1*.5 + empft1 + nmgrs1  //   Full-time equivalency, Card and Krueger represent FTE with number of FT employees plus .5* the number of part time employees plus the number of managers                                           
gen emptot2 = emppt2*.5 + empft2 + nmgrs2                                            
gen demp = emptot2 - emptot1 // difference in employment                                                          
                                                                                
gen pchempc = 2*(emptot2-emptot1)/(emptot2+emptot1) // percent change in employment                          
replace pchempc = -1 if emptot2 == 0                                                 
                                                                                
gen dwage = wage_st2 - wage_st1  //changes in wages                                                       
gen pchwage = (wage_st2 - wage_st1)/wage_st1 // percent change in wage       
                                                                                
gen nj = stater // state is a variable with 0 = PA and 1 = NJ so I treat it as a NJ dummy variable

table nj, statistic(mean emptot1 emptot2 demp) statistic(semean emptot1 emptot2 demp) nototals

table nj if emptot1 < . & emptot2 < ., statistic(mean emptot1 emptot2 demp) statistic(semean emptot1 emptot2 demp) nototals

tabstat emptot1 emptot2 demp, stats(mean semean) by(nj) nototal


*recreate 
reshape long ncalls empft emppt nmgrs wage_st inctime firstinc special meals open hrsopen psoda pfry pentree nregs nregs11am emptot, i(sheet) j(wave)

gen njmw = nj*(wave == 2)

xtset sheet wave

xtdidregress (emptot) (njmw), group(sheet) time(wave)

reg emptot nj i.wave njmw

*difference-in-difference tables constructed using reshaped tables
gen post = wave-1  
diff emptot, t(nj) p(post)

reg emptot i.nj##i.wave
margins nj#wave
etable, margins


*before and after graph of wages in NJ
histogram wage_st if nj == 1, by (wave)

*Bar graphs replicating figure 1

gen statel = "NJ" if nj == 1
replace statel = "PA" if nj == 0

bihist wage_st if wave == 1, by(statel) fraction

bihist wage_st if wave == 2, by(statel) fraction