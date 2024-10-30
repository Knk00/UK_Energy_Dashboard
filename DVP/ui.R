library(shiny)
library(shinydashboard)
library(shinythemes)
library(plotly)

# Define UI for application
ui <- navbarPage(
  title = "UK Energy Dashboard",
  theme = shinytheme("flatly"),  # Using a clean, flat theme for modern appearance
  tabPanel("Home",
           fluidPage(
             tags$head(
               tags$style(HTML("
                 .streamgraph-tooltip {
                     font-size: 16px !important;
                     font-weight: bold;
                     color: #1b998b;
                   }
                 .main-title, .tagline { text-align: center; color: #3A7CA5; }
                 .section { display: flex; align-items: center; justify-content: space-around; margin-bottom: 40px; }
                 .text-section { width: 50%; text-align: center; }
                 .image-section { width: 50%; align-items:right;}
                 img { width: 100%; height: auto; }
                 .introduction { margin-bottom: 40px; font-size: 18px;}
                 h4 {text-align: left; }
                 h3 {text-align: left; }
                 h2 {text-align: left; margin-bottom:20px;width:100%;}
                 h1 {margin-bottom: 20px; text-align: left;}
                 p {text-align: left; font-size:18px;}
                 body {margin: 20px;}
               "))
             ),
             
             tags$script(HTML("
                $(document).on('mousemove', '.stream-tooltip', function(e) {
                  $(this).css({
                    left: e.pageX + 90 + 'px',  // Shift tooltip slightly right
                    top: e.pageY + 15 + 'px'    // Shift tooltip slightly down
                  });
                });
              ")),
             
             div(class = "main-title",
                 tags$h1("UK Energy Dashboard", style="font-size: 55px;text-align: center")
             ),
             div(class = "tagline",
                 tags$p("Tracking Energy Evolution, Sustainability, and Carbon Emissions.",
                        style = "text-align: center; font-size:18px;margin-right:20px")
             ),
             div(class = "introduction",
                 tags$h1("Introduction"),
                 tags$p("The UK Energy Dashboard provides a comprehensive view into the UK's electricity consumption trends from 2009 to 2024, focusing on the transition from fossil fuels to renewable energy sources and its impact on carbon emissions.")
             ),
             div(class = "section",
                 div(class = "text-section",
                     tags$h1("Exploring Key Research Questions & Identifying Stakeholders"),
                     tags$h3("Impact of Renewable Shift on Carbon Intensity"),
                     tags$p("How have the shifts in electricity consumption from fossil fuels to renewable energy sources influenced the carbon intensity of the UK's electricity grid from 2009 to 2024? What role do factors such as energy storage, interconnector flows, and demand play in modulating this relationship? Also, how does the UK stand on the global stage?")
                 ),
                 div(class = "image-section",
                     img(src = "https://ymail.info/wp-content/uploads/2024/08/Wind-and-Solar-Surpass-Fossil-Fuels-in-the-EU-A-Milestone-for-Renewable-Energy.webp", 
                         style = "width: 50%; height: auto;margin-left:100px;")
                 )
             ),
             div(class = "section",
                 div(class = "text-section",
                     tags$h3("TSD Contribution and Regional Power Consumption"),
                     tags$p("How much of the TSD is contributed by station load, pump storage pumping, and interconnector exports? Additionally, how much power was consumed by England and Wales in comparison to the entire nation?")
                 ),
                 div(class = "image-section",
                     img(src = "https://www.aquaswitch.co.uk/wp-content/uploads/2023/03/interconnectormap800w.webp", 
                         style = "width: 50%; height: auto;margin-left:100px;")
                 )
             )
           )),
  tabPanel("Research & Analysis",
           fluidPage(
             tags$h1("Energy Consumption Evolution"),
             tags$p("Detailed analysis of the impact of renewable energy shift on carbon intensity and more.", style="margin-right:50px;"),
             fluidRow(
               column(4,
                      wellPanel(
                        tags$h4("Interactive Filters",style="margin-left:5px;"),
                        selectInput("timeResolution", "Select Time Resolution:",
                                    choices = c("Monthly", "Yearly")),
                        tags$p("Use the dropdown to switch between monthly and yearly views of the data. Hover over the plot points to view detailed information for each time point.",
                               style="font-size:14px;")
                      )),
               column(8,
                      plotlyOutput("energyPlot")),
               column(12,
                      tags$h2("Analysis Insights"),
                      tags$p("The plot above provides insights into how national demand has fluctuated over time. Significant dips and rises might correlate with government policy changes, major trade adjustments, or global economic events.")
               ),
               column(12,
                      tags$h1("Sustainable Energy Transition",style="margin-top:50px;margin-bottom:30px;"),
                      tags$p("A stream graph will be added here, showing the transition over the years across various energy sources, highlighting the shift towards more sustainable energy options.")
               )
             ),
             fluidRow(
               column(4,
                      wellPanel(
                        tags$h4("Interactive Filters"),
                        selectInput("timeResolutionStream", "Select Time Resolution:",
                                    choices = c("Monthly", "Yearly"))
                      )),
               column(8, streamgraphOutput("energyStreamGraph"))  # Ensure correct output function
             )
           )),
  tabPanel("Data Sources",
           fluidPage(
             tags$h3("Data Sources and Acknowledgements"),
             tags$p("This application uses data from multiple sources which are continuously updated."),
             tags$ul(
               tags$li("National ESO Grid"),
               tags$li("Kaggle"),
               tags$li("Our World in Data")
             )
           ))
)
