
#' Plot the cumulative lift curve of a sort-order.
#'
#' Plot the cumulative lift curve of a sort-order.
#'
#' The use case for this visualization is to compare a predictive model
#' score to an actual outcome (either binary (0/1) or continuous). In this case the
#' lift curve plot measures how well the model score sorts the data compared
#' to the true outcome value.
#'
#' The x-axis represents the fraction of items seen when sorted by score, and the
#' y-axis represents the lift seen so far (cummulative value of model over cummulative value of random selection)..
#'
#' For comparison, \code{LiftCurvePlot} also plots the "wizard curve": the lift curve when the
#' data is sorted according to its true outcome.
#'
#' To improve presentation quality, the plot is limited to approximately \code{large_count} points (default: 1000).
#' For larger data sets, the data is appropriately randomly sampled down before plotting.
#'
#'
#' @param frame data frame to get values from
#' @param xvar name of the independent (input or model score) column in frame
#' @param truthVar name of the dependent (output or result to be modeled) column in frame
#' @param title title to place on plot
#' @param ...  no unnamed argument, added to force named binding of later arguments.
#' @param large_count numeric, upper bound target for number of plotting points
#' @param include_wizard logical, if TRUE plot the ideal or wizard plot.
#' @examples
#'
#' set.seed(34903490)
#' y = abs(rnorm(20)) + 0.1
#' x = abs(y + 0.5*rnorm(20))
#' frm = data.frame(model=x, value=y)
#' WVPlots::LiftCurvePlot(frm, "model", "value",
#'    title="Example Continuous Lift Curve")
#'
#' @export
LiftCurvePlot = function(frame, xvar, truthVar, title,
                         ...,
                         large_count = 1000,
                         include_wizard = TRUE) {
  frame <- check_frame_args_list(...,
                                 frame = frame,
                                 name_var_list = list(xvar = xvar, truthVar = truthVar),
                                 title = title,
                                 funname = "WVPlots::LiftCurvePlot")
  pct_outcome <- pctpop <- sort_criterion <- NULL # mark as not unbound variables
  truthcol <- as.numeric(frame[[truthVar]])
  predcol <- as.numeric(frame[[xvar]])
  # data frame of pred and truth, sorted in order of the predictions
  d = data.frame(predcol = predcol, truthcol = truthcol)
  n <- nrow(d)
  predord = order(d[['predcol']],
                  sample.int(n, n, replace = FALSE),
                  decreasing = TRUE) # reorder, with highest first
  wizard = order(d[['truthcol']],
                 sample.int(n, n, replace = FALSE),
                 decreasing = TRUE)
  npop = dim(d)[1]

  # data frame the cumulative prediction/truth as a function
  # of the fraction of the population we're considering, highest first
  results = data.frame(
    pctpop = (1:npop) / npop,
    model = cumsum(d[predord, 'truthcol']) / sum(d[['truthcol']]),
    wizard = cumsum(d[wizard, 'truthcol']) / sum(d[['truthcol']])
  )
  results$model_lift <- results$model/results$pctpop
  results$wizard_lift <- results$wizard/results$pctpop


  # transform the frame into the tall form, for plotting
  r1 <- data.frame(pctpop = results$pctpop,
                   pct_outcome = results$model_lift,
                   sort_criterion = "model",
                   stringsAsFactors = FALSE)
  r2 <- data.frame(pctpop = results$pctpop,
                   pct_outcome = results$wizard_lift,
                   sort_criterion = "wizard",
                   stringsAsFactors = FALSE)
  results <- rbind(r1, r2)
  # rename sort_criterion
  sortKeyM <- c('model' = paste('model: sort by', xvar),
                'wizard' = paste('wizard: sort by', truthVar))
  results$sort_criterion <- sortKeyM[results$sort_criterion]
  # rename levels of sort criterion
  colorKey = as.character(sortKeyM) %:=% c('darkblue', 'darkgreen')
  names(colorKey) = c(paste('model: sort by', xvar),
                      paste('wizard: sort by', truthVar))
  modelKey = names(colorKey)[[1]]

  if(!include_wizard) {
    results <- results[results$sort_criterion=="model: sort by model", , drop=FALSE]
  }

  # cut down the number of points
  results <- thin_frame_by_orders(results,
                                  c("pctpop", "pct_outcome"),
                                  "sort_criterion",
                                  large_count)

  # plot
  gplot = ggplot2::ggplot(data = results) +
    ggplot2::geom_point(
      mapping = ggplot2::aes(
        x = pctpop,
        y = pct_outcome,
        color = sort_criterion,
        shape = sort_criterion
      ),
      alpha = 0.5
    ) +
    ggplot2::geom_line(
      mapping = ggplot2::aes(
        x = pctpop,
        y = pct_outcome,
        color = sort_criterion,
        linetype = sort_criterion
      )
    ) +
    ggplot2::ggtitle(
      title,
      subtitle =
      paste0(
        truthVar,
        '~',
        xvar)) +
    ggplot2::xlab("fraction items in sort order") +
    ggplot2::ylab("lift") +
    ggplot2::scale_x_continuous(breaks = seq(0, 1, 0.1)) +
    ggplot2::scale_color_manual(values = colorKey) +
    ggplot2::theme(legend.position = "bottom")
  gplot
}
