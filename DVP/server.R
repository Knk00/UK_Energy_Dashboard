# server.R

library(shiny)
library(ggplot2)
library(dplyr)
library(lubridate)  # For date parsing
library(plotly)
library(streamgraph)
library(tidyr)
library(leaflet)
library(sf)

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
  
  # Prepare flow data by selecting relevant columns
  flow_data <- data_monthly %>%
    select(timestamp, ifa_flow, ifa2_flow, britned_flow, moyle_flow, east_west_flow, nemo_flow)
  
  # Load the DNO shapefile and transform it to WGS84 (long/lat)
  dno_shapefile <- st_read("../Data/GB DNO License Areas 20240503 as ESRI Shape File.shp") %>%
    st_transform(crs = 4326)
  
  # Country coordinates for interconnector flows
  countries <- data.frame(
    country = c("France", "Netherlands", "Belgium", "Ireland", "Norway"),
    lat = c(48.85, 52.37, 50.85, 53.41, 59.91),
    lon = c(2.35, 4.90, 4.35, -8.24, 10.75)
  )
  
  # Render the initial map with DNO areas
  output$dnoMap <- renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      setView(lng = -1.5, lat = 54.0, zoom = 5) %>%
      addPolygons(
        data = dno_shapefile,
        fillColor = "lightblue",
        color = "black",
        weight = 1,
        opacity = 1,
        fillOpacity = 0.6,
        label = ~DNO_Full
      )%>%
      # Adding a Legend
      addLegend(
        position = "bottomright",
        colors = c("green", "red"),
        labels = c("Import", "Export"),
        title = "Flow Direction",
        opacity = 1
      )
  })
  
  # Update map with interconnector flows based on selected year
  observeEvent(input$year, {
    # Filter flow data for the selected year
    selected_flow <- flow_data %>%
      filter(format(as.Date(timestamp, "%Y-%m-%d"), "%Y") == input$year)
    
    # Clear previous layers
    leafletProxy("dnoMap") %>% clearShapes()
    
    # Add arrows for each interconnector
    for (i in 1:nrow(countries)) {
      interconnector <- names(selected_flow)[i + 1]  # Skip timestamp column
      flow_value <- selected_flow[[interconnector]]
      
      # Determine the flow direction and color
      direction <- ifelse(flow_value >= 0, "Import", "Export")
      color <- ifelse(direction == "Import", "green", "red")
      
      # Draw line from the UK to the target country
      leafletProxy("dnoMap") %>%
        addPolylines(
          lng = c(-1.5, countries$lon[i]),  # UK to target country
          lat = c(54.0, countries$lat[i]),
          color = color,
          weight = abs(flow_value) / 100,  # Scale line thickness by flow value
          label = paste(interconnector, ":", round(flow_value, 2), "MW (", direction, ")")
        )
    }
  })
}
