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
    
    # Define key events with respective dates
    key_events <- data.frame(
      event = c("COVID-19 Pandemic"),
      date = as.Date(c("2020-03-01"))
    )
    
    # Create the ggplot with vertical lines for events
    p <- ggplot(data, aes(x = timestamp, y = nd)) +
      geom_point(color = "#1f77b4", size = 2, shape = 21, fill = "#1f77b4") +
      geom_line(color = "#1f77b4") +
      
      # Add vertical lines for events with labels
      geom_vline(data = key_events, aes(xintercept = as.numeric(date)), 
                 color = "lightcoral", linetype = "dashed", size = 1) +
      geom_text(data = key_events, aes(x = date, y = max(data$nd), label = event),
                angle = 90, hjust = -0.1, nudge_x = 15, size = 4, color = "lightcoral") +
      
      # Customize labels and theme
      labs(
        title = "Evolution of Energy Consumption",
        x = "Date",
        y = "National Demand (MW)"
      ) +
      theme_minimal() +
      theme(
        plot.background = element_rect(fill = "ghostwhite"),  # Livelier background
        panel.background = element_rect(fill = "ghostwhite"),
        panel.grid.major = element_line(color = "gray", linetype = "dashed"),
        plot.title = element_text(size = 18, hjust = 0.5),
        axis.title.x = element_text(size = 12),
        axis.title.y = element_text(size = 12)
      )
    
    # Convert to an interactive Plotly object
    ggplotly(p) %>%
      layout(legend = list(orientation = "h", y = -0.2))  # Adjust legend position if needed
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
  flow_data <- data_yearly %>%
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
  
 
  # Create a consistent weight for all pipelines and dynamic flows
  pipeline_weight <- 5  # Set a fixed pipeline width
  
  # Render the map with static pipelines
  output$dnoMap <- renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      setView(lng = -1.5, lat = 54.0, zoom = 5) %>%
      
      # DNO areas in light blue
      addPolygons(
        data = dno_shapefile,
        fillColor = "lightblue",
        color = "black",
        weight = 1,
        opacity = 1,
        fillOpacity = 0.6,
        label = ~DNO_Full
      ) %>%
      
      # Add static pipelines in consistent gray
      addPolylines(
        lng = c(-1.5, countries$lon),
        lat = c(54.0, countries$lat),
        color = "gray", 
        weight = pipeline_weight,  # Use consistent weight
        opacity = 0.5,  # Slight transparency to prevent visual overload
        group = "staticPipelines"
      ) %>%
      
      # Add a legend to indicate import and export
      addLegend(
        position = "bottomright",
        colors = c("green", "red"),
        labels = c("Import", "Export"),
        title = "Flow Direction",
        opacity = 1
      )
  })
  
  # Update map with dynamic flows based on selected year
  observeEvent(input$year, {
    selected_flow <- flow_data %>%
      filter(format(as.Date(timestamp), "%Y") == input$year)
    
    # Clear previous dynamic flows
    leafletProxy("dnoMap") %>% clearGroup("dynamicFlows")
    
    # Draw dynamic flows for each interconnector
    for (i in 1:nrow(countries)) {
      interconnector <- names(selected_flow)[i + 1]
      flow_value <- selected_flow[[interconnector]]
      
      # Determine direction and corresponding color
      direction <- ifelse(flow_value >= 0, "Import", "Export")
      flow_color <- ifelse(direction == "Import", "green", "red")
      
      # Calculate opacity based on flow magnitude (scaled to 0.1-1 range)
      flow_opacity <- max(0.1, min(abs(flow_value) / 500, 1))
      
      # Add dynamic flow lines
      leafletProxy("dnoMap") %>%
        addPolylines(
          lng = c(-1.5, countries$lon[i]),  # From UK to target country
          lat = c(54.0, countries$lat[i]),
          color = flow_color,
          weight = pipeline_weight,  # Keep weight consistent
          opacity = flow_opacity,  # Adjust opacity based on flow magnitude
          label = paste(interconnector, ":", round(flow_value, 2), "MW (", direction, ")"),
          group = "dynamicFlows",
          labelOptions = labelOptions(noHide = FALSE, textsize = "12px", direction = "center")
        )
    }
  })
  
  combined_data <- read.csv("../Data/combined_forecast_data.csv", stringsAsFactors = FALSE)
  combined_data$timestamp <- as.Date(combined_data$timestamp)
  
  # Separate historical and forecast data
  historical_data <- combined_data %>% filter(type == "Historical")
  forecast_data <- combined_data %>% filter(type == "Forecast")
  
  # Forecast Plot 1: Low Carbon, Renewables, and National Demand
  output$forecastPlot1 <- renderPlotly({
    p1 <- ggplot() +
      # Plot Historical Data (solid lines)
      geom_line(data = historical_data, aes(x = timestamp, y = LOW_CARBON, color = "Low Carbon"), size = 1) +
      geom_line(data = historical_data, aes(x = timestamp, y = RENEWABLE, color = "Renewable"), size = 1) +
      geom_line(data = historical_data, aes(x = timestamp, y = DEMAND, color = "National Demand"), size = 1) +
      
      # Plot Forecast Data (dashed lines)
      geom_line(data = forecast_data, aes(x = timestamp, y = LOW_CARBON), color = "blue", linetype = "dashed", size = 1) +
      geom_line(data = forecast_data, aes(x = timestamp, y = RENEWABLE), color = "green", linetype = "dashed", size = 1) +
      geom_line(data = forecast_data, aes(x = timestamp, y = DEMAND), color = "orange", linetype = "dashed", size = 1) +
      
      # Confidence Interval for Forecast Data
      geom_ribbon(
        data = forecast_data, aes(x = timestamp, ymin = LOW_CARBON - 500, ymax = LOW_CARBON + 500),
        fill = "blue", alpha = 0.2
      ) +
      
      # Customize axes
      scale_x_date(date_labels = "%Y", date_breaks = "1 year") +
      labs(
        # title = "Forecast of Low Carbon, Renewables, and National Demand",
        subtitle = "5-Year Projection with Confidence Interval",
        x = "Year", y = "MW",
        color = "Metric", linetype = "Data Type"
      ) +
      theme_minimal() +
      theme(
        plot.title = element_text(size = 18, hjust = 0.5),
        legend.position = "bottom",
        legend.text = element_text(size=14)
      )
    
    # Convert to Plotly
    ggplotly(p1) %>%
      layout(legend = list(orientation = "h", y = -0.2))
  })
  
  # Forecast Plot 2: Carbon Intensity
  output$forecastPlot2 <- renderPlotly({
    p2 <- ggplot() +
      # Plot Historical Carbon Intensity (solid line)
      geom_line(data = historical_data, aes(x = timestamp, y = CARBON_INTENSITY, color = "Carbon Intensity"), size = 1) +
      
      # Plot Forecast Carbon Intensity (dashed line)
      geom_line(data = forecast_data, aes(x = timestamp, y = CARBON_INTENSITY), color = "red", linetype = "dashed", size = 1) +
      
      # Confidence Interval for Carbon Intensity Forecast
      geom_ribbon(
        data = forecast_data, aes(x = timestamp, ymin = CARBON_INTENSITY - 20, ymax = CARBON_INTENSITY + 20),
        fill = "red", alpha = 0.2
      ) +
      
      # Customize axes
      scale_x_date(date_labels = "%Y", date_breaks = "1 year") +
      labs(
        # title = "Forecast of Carbon Intensity",
        subtitle = "5-Year Projection with Confidence Interval",
        x = "Year", y = "g/kWh",
        color = "Metric", linetype = "Data Type"
      ) +
      theme_minimal() +
      theme(
        plot.title = element_text(size = 18, hjust = 0.5),
        legend.position = "bottom",
        legend.text = element_text(size=14)
      )
    
    # Convert to Plotly
    ggplotly(p2) %>%
      layout(legend = list(orientation = "h", y = -0.2))
  })
  
  # Observe the click event on the action link and switch to the 'Research & Analysis' tab
  observeEvent(input$toResearch, {
    updateNavbarPage(session, "navbar", selected = "Research & Analysis")
  })
}
