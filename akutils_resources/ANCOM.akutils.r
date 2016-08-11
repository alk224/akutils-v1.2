ANCOM <- function (real.data, sig = 0.05, multcorr = 3, tau = 0.02, theta = 0.1) 
{
    #no_cores <- detectCores() - 1

    colnames(real.data)[dim(real.data)[2]] <- "Group"
    real.data$Group <- factor(real.data$Group)
    real.data <- data.frame(real.data[which(is.na(real.data$Group) == 
        F), ], row.names = NULL)
    num_OTU <- ncol(real.data) - 1
    W.detected <- ancom.detect(real.data, num_OTU, sig, multcorr, 
        ncore = ncores)
    W_stat <- W.detected
    if (num_OTU < 10) {
        detected <- colnames(real.data)[which(W.detected > num_OTU - 
            1)]
    }
    else {
        if (max(W.detected)/num_OTU >= theta) {
            c.start <- max(W.detected)/num_OTU
            cutoff <- c.start - c(0.05, 0.1, 0.15, 0.2, 0.25)
            prop_cut <- rep(0, length(cutoff))
            for (cut in 1:length(cutoff)) {
                prop_cut[cut] <- length(which(W.detected >= num_OTU * 
                  cutoff[cut]))/length(W.detected)
            }
            del <- rep(0, length(cutoff) - 1)
            for (ii in 1:(length(cutoff) - 1)) {
                del[ii] <- abs(prop_cut[ii] - prop_cut[ii + 1])
            }
            if (del[1] < tau & del[2] < tau & del[3] < tau) {
                nu = cutoff[1]
            }
            else if (del[1] >= tau & del[2] < tau & del[3] < 
                tau) {
                nu = cutoff[2]
            }
            else if (del[2] >= tau & del[3] < tau & del[4] < 
                tau) {
                nu = cutoff[3]
            }
            else {
                nu = cutoff[4]
            }
            up_point <- min(W.detected[which(W.detected >= nu * 
                num_OTU)])
            W.detected[W.detected >= up_point] <- 99999
            W.detected[W.detected < up_point] <- 0
            W.detected[W.detected == 99999] <- 1
            detected <- colnames(real.data)[which(W.detected == 
                1)]
        }
        else {
            W.detected <- 0
            detected <- "No significant OTUs detected"
        }
    }
    results <- list(W = W_stat, detected = detected, dframe = real.data)
    class(results) <- "ancom"
    return(results)
}

