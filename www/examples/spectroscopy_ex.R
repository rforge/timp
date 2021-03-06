##############################
## load TIMP
##############################

require(TIMP)

##############################
## READ IN DATA 
##############################

C1 <- readData("streak_ex.txt", typ="plain")

##############################
## PREPROCESS DATA
##############################

## select times with index 10 - 923 for modeling  
C1_1 <- preProcess(data = C1, sel_time = c(10,923))

## select wavelenths with index 10 - 923 for modeling  
C1_1 <- preProcess(data = C1_1, sel_lambda = c(1,48))

##############################
## SPECIFY K Matrix and J vector 
##############################

## initialize 2 7x7 arrays to 0 

delK <- array(0, dim=c(5,5,2)) 

## the matrix is indexed: 
## delK[ ROW K MATRIX, COL K MATRIX, matrix number] 

## in the first matrix, put the index of a parameter that describes
## and allowed transition
## for example delK[3,2,1] <- 6 means that there is a transition from
## compartment 3 to compartment 2, and that this transition is parameterized
## by kinpar 6.

delK[2:5,1,1] <- 1
delK[2,2,1] <- 2
delK[3,2,1] <- 6
delK[4,2,1] <- 7
delK[2,3,1] <- 6
delK[3,3,1] <- 3
delK[2,4,1] <- 7
delK[4,4,1] <- 4
delK[5,5,1] <- 5

## in the second matrix, put the indices of the parameters that
## describe branching

delK[2,1,2] <- 1
delK[3,1,2] <- 2
delK[4,1,2] <- 3
delK[5,1,2] <- 4
delK[2,3,2] <- 5
delK[2,4,2] <- 6

## print out the resulting array to make sure it's right

delK

jvector <- c(1,0,0,0,0)

##############################
## SPECIFY INITIAL MODEL
##############################

model1 <- initModel(mod_type = "kin",  
## parameters for decay
kinpar = c(2.3754,0.3696243092E-01, 0.0445,0.0039,0.2328529517E-03,
0.7624564320E-01,0.3561399132E-01),
## parameters for branching of decay 
kinscal = c(0.8504, 0.067357, 0.025259, 0.057, 1.603108393739, .6),
## parameter values not optimized 
fixed = list(jvec=1:5, irfpar=1:4, kinpar=1:3, kinscal=c(1:4)),
## IRF parameters
irfpar=c( -84.26103210, 1.520081997, 19.14718437, 0.7385417074E-01), 
## transition matrix for compartmental model, input vector  
kmat = delK, jvec = jvector, 
## wavenumber regions in which concentration is fixed to 0 for a compartment 
clp0 = list(list(low=100,high=1000, comp=1), 
list(low=100,high=690,comp=3),
list(low=100,high=697,comp=4)),
## use double Gaussian model for the IRF                    
doublegaus = TRUE,
## are treating streak data, so that a correction is made for the
## addition to the data of a 'backsweep' term that depends on the
## period of the instrument given in streakT
streak = TRUE, 
streakT = 13140.6044678)

##############################
## FIT MODEL 
##############################

serRes<-fitModel(list(C1_1), list(model1), 
opt=kinopt(iter=20, title="Streak", output="pdf",
plotkinspec = TRUE, noplotest = TRUE, stderrclp = TRUE,kinspecerr=TRUE,
selectedtraces = seq(1, length(C1_1@x2), by=1), 
makeps = "streak", linrange = 20))

##############################
## MAKE ADDITIONAL PLOTS 
##############################

## get concentrations at wavelength 30
CL <- getXList(serRes, group=30)[[1]]

## get spectra
EL <- getCLP(serRes, dataset=1)
err <- getCLP(serRes, getclperr = TRUE, dataset=1)

colvec <- grey(seq(0,.6,length=4))

## plot concentrations 
postscript("C.ps", width=10, height=5)

par(cex.axis=2, cex.lab=2, mar=c(5,5,2,2))

matlinlogplot(C1_1@x, CL, mu = serRes$currTheta[[1]]@irfpar[1],
               alpha = 20, col=colvec, type="l", lwd=3,
               ylab="concentration", xlab="time (ps)")

legend(23, .57, legend=c("component 2","component 3","component 4",
                  "component 5"),  col=colvec, cex=1.5,lwd=3, lty=1:5)

dev.off()

## plot of spectra 
postscript("E.ps", width=10, height=5)

par(cex.axis=2, cex.lab=2, mar=c(5,5,2,2))

matplot(C1_1@x2, EL[,-1], col=colvec, type="l", lwd=3,
        ylab="amplitude", xlab="wavelength (nm)")


for(i in 1:(ncol(EL)-1)) {
  plotCI(C1_1@x2, EL[,i], uiw=err[,i], lwd=3, pch=NA,
         ylab="amplitude", xlab="wavelength (nm)", add=TRUE,
         sfrac = 0, type="p", gap = 0, labels = "", lty=1)
}  

dev.off()

## plot of data and model 

xx <- getData(serRes)
xx1 <- getTraces(serRes)

postscript("R.ps", width=10, height=5)

par(mfrow=c(4,2), cex.axis=2, cex.lab=2,mar=c(2,3,1,1), cex.main=2)

colvec2 <- c(grey(.6), 1)

plvec <- seq(12, C1_1@nl, length=8)

for(i in plvec) {

  par(adj=.5)
  matlinlogplot(C1_1@x, cbind(xx[,i],  xx1[,i]),
                mu = serRes$currTheta[[1]]@irfpar[1], lwd=2,
                alpha = 20, col=colvec2, type="l", lty=1,
                ylab="",xlab="")
  par(adj=1)
  title(substitute(paste(lambda * " = " * mt * " nm"),
     list(mt = signif(C1_1@x2[i], digits=3))), line=-1)
    
}

dev.off()

