ancom.detect <- function (otu_data, n_otu, alpha, multcorr, ncore) 
{
    Group <- otu_data[, ncol(otu_data)]
    if (length(unique(Group)) == 2) {
        tfun <- exactRankTests::wilcox.exact
    }
    else {
        tfun <- stats::kruskal.test
    }
    if (TRUE) {
        registerDoParallel(cores = ncore)
        aa <- bb <- NULL
        logratio.mat <- foreach(bb = 1:n_otu, .combine = "rbind", 
            .packages = "foreach") %:% foreach(aa = 1:n_otu, 
            .combine = "c", .packages = "foreach") %dopar% {
            if (aa == bb) {
                p_out <- NA
            }
            else {
                data.pair <- otu_data[, c(aa, bb, n_otu + 1)]
                lr <- log((0.001 + as.numeric(data.pair[, 1]))/(0.001 + 
                  as.numeric(data.pair[, 2])))
                lr_dat <- data.frame(lr = lr, Group = Group)
                p_out <- tfun(lr ~ Group, data = lr_dat)$p.value
            }
            p_out
        }
        rownames(logratio.mat) <- colnames(logratio.mat) <- NULL
    }
    else {
        logratio.mat <- matrix(NA, nrow = n_otu, ncol = n_otu)
        for (ii in 1:(n_otu - 1)) {
            for (jj in (ii + 1):n_otu) {
                data.pair <- otu_data[, c(ii, jj, n_otu + 1)]
                lr <- log((0.001 + as.numeric(data.pair[, 1]))/(0.001 + 
                  as.numeric(data.pair[, 2])))
                lr_dat <- data.frame(lr = lr, Group = Group)
                logratio.mat[ii, jj] <- tfun(lr ~ Group, data = lr_dat)$p.value
            }
        }
        ind <- lower.tri(logratio.mat)
        logratio.mat[ind] <- t(logratio.mat)[ind]
    }
    logratio.mat[which(is.finite(logratio.mat) == FALSE)] <- 1
    mc.pval <- t(apply(logratio.mat, 1, function(x) {
        s <- p.adjust(x, method = "BH")
        return(s)
    }))
    a <- logratio.mat[upper.tri(logratio.mat, diag = FALSE) == 
        TRUE]
    b <- matrix(0, ncol = n_otu, nrow = n_otu)
    b[upper.tri(b) == T] <- p.adjust(a, method = "BH")
    diag(b) <- NA
    ind.1 <- lower.tri(b)
    b[ind.1] <- t(b)[ind.1]
    if (multcorr == 1) {
        W <- apply(b, 1, function(x) {
            subp <- length(which(x < alpha))
        })
    }
    else if (multcorr == 2) {
        W <- apply(mc.pval, 1, function(x) {
            subp <- length(which(x < alpha))
        })
    }
    else if (multcorr == 3) {
        W <- apply(logratio.mat, 1, function(x) {
            subp <- length(which(x < alpha))
        })
    }
    return(W)
}

