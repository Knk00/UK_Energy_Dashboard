library(shiny)
library(ggplot2)
library(dplyr)
library(lubridate)  # For date parsing
library(plotly)
library(streamgraph)
library(tidyr)

# Color palette as provided
pal <- c("#d7263d", "#f46036", "#FFB400", "#13AFEF", "#1b998b", 
         "#c5d86d", "#d82e3f", "#70c1b3", "#ffe066", "#247ba0")

# Define server logic
server <- function(input, output, session) {
  
  # Read the datasets
  data_monthly <- read.csv("../Data/monthly_merged.csv", header = TRUE, stringsAsFactors = FALSE)
  data_yearly <- read.csv("../Data/yearly_merged_cleaned.csv", header = TRUE, stringsAsFactors = FALSE)
  
  # Convert timestamp to Date object
  data_monthly$timestamp <- dmy(data_monthly$timestamp)
  data_yearly$timestamp <- dmy(data_yearly$timestamp)
  
  stream_data_monthly <- data_monthly %>%
    select(timestamp, GAS, COAL, NUCLEAR, WIND, HYDRO, IMPORTS, BIOMASS, OTHER, SOLAR, STORAGE)
  
  stream_data_yearly <- data_yearly %>%
    select(timestamp, GAS, COAL, NUCLEAR, WIND, HYDRO, IMPORTS, BIOMASS, OTHER, SOLAR, STORAGE)
  
  
  # Reactive expression to switch data based on input
  filtered_data <- reactive({
    if(input$timeResolution == "Monthly") {
      data_monthly
    } else {
      data_yearly
    }
  })
  
  # Output for energy consumption plot
  output$energyPlot <- renderPlotly({
    data <- filtered_data()
    p <- ggplot(data, aes(x = timestamp, y = nd)) +
      geom_point(color = "#1f77b4", size = 2, shape = 21, fill = "#1f77b4") +
      geom_line(color = "#1f77b4") +
      labs(title = "Evolution of Energy Consumption",
           x = "Date",
           y = "National Demand (MW)") +
      theme_minimal() +
      theme(
        plot.background = element_rect(fill = "ghostwhite"),  # Livelier background
        panel.background = element_rect(fill = "ghostwhite"),
        panel.grid.major = element_line(color = "gray", linetype = "dashed"),
        plot.title = element_text(size=18, hjust=0.5),
        axis.title.x = element_text(size=12),
        axis.title.y = element_text(size=12),
        # axis.label.x = element_text(size=16,margin=margin(t=20)),
        # axis.label.y = element_text(size=16,margin=margin(r=40)),
      )
    
    ggplotly(p)
  })
  
  # Reactive expression to switch between monthly and yearly datasets
  streamgraph_data <- reactive({
    if (input$timeResolutionStream == "Monthly") {
      stream_data_monthly  # Use preloaded monthly data
    } else {
      stream_data_yearly  # Use pre-aggregated yearly data directly
    }
  })
  
  # Render the streamgraph as HTML
  output$energyStreamGraph <- renderStreamgraph({
    gathered_data <- streamgraph_data() %>%
      gather(
        key = "EnergySource", value = "Value", 
        c("GAS", "COAL", "NUCLEAR", "WIND", "HYDRO", 
          "IMPORTS", "BIOMASS", "OTHER", "SOLAR", "STORAGE")
      )
    
    gathered_data$timestamp <- as.Date(gathered_data$timestamp)  # Ensure it is in Date format
    
    print(head(gathered_data))
    
    # Check if the gathered data is non-empty
    if (nrow(gathered_data) == 0) {
      return(tags$p("No data available to display."))
    }
    
    # Create the streamgraph
    sg <- gathered_data %>%
      streamgraph("EnergySource", "Value", "timestamp", offset = "zero", interpolate = "basis") %>%
      sg_legend(TRUE, "Energy Source:") %>%
      sg_axis_x(tick_interval = 12, tick_format = "%Y-%m") %>%
      sg_fill_manual(values = pal)
    
    sg
  })
}
