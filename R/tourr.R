# # touring stuffs
# initTour <- reactive({
#   mat <- scales::rescale(as.matrix(cog[input$tourVars]))
#   tour <- new_tour(mat, grand_tour(), NULL)
#   list(
#     mat = mat,
#     tour = tour,
#     step = tour(1)
#   )
# })
# 
# iterTour <- reactive({
#   tr <- initTour()
#   if (input$play) invalidateLater(1000 / 30, NULL)
#   tr$step <- tr$tour(2 / 30) # you always want 30 frames/second, right?
#   list(
#     mat = tr$mat,
#     tour = tr$tour,
#     step = tr$step
#   )
# })
# 
# tourDat <- reactive({
#   tr <- iterTour()
#   tDat <- setNames(
#     data.frame(cog[, 1], tr$mat %*% tr$step$proj), 
#     c("ID", "x", "y")
#   )
#   inner_join(selectHandler(), tDat, by = "ID")
# })
# 
# output$tourPlot <- renderPlotly({
#   dat <- inner_join(tourDat(), sensors[c("ID", "Description")], by = "ID")
#   plot_ly(
#     dat, x = x, y = y, text = Description, key = ID,
#     mode = "markers", hoverinfo = "text", marker = list(color = toRGB(fill, 0.5))
#   ) %>% layout(
#     width = 400, height = 400, showlegend = FALSE,
#     xaxis = list(title = "", range = c(-1, 1)), 
#     yaxis = list(title = "", range = c(-1, 1))
#   )
# })

# 
# column(
#   width = 3,
#   h4("Touring controls:"),
#   checkboxInput("play", "Start Grand Tour:", value = FALSE),
#   selectizeInput(
#     "tourVars", "Touring variables:", multiple = TRUE, 
#     names(cog)[-1], names(cog)[-1]
#   )
# )