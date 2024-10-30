# app.R

library(shiny)
addResourcePath("Images", "../Images")


# Load UI and server components
source("ui.R")
source("server.R")

# Run the Shiny application
shinyApp(ui = ui, server = server)
