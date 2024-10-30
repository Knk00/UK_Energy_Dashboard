library(shiny)
library(shinydashboard)
library(shinythemes)
library(plotly)
library(streamgraph)
library(leaflet)

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
                 p {text-align: justify; font-size:16px;}
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
                 tags$p("The UK Energy Dashboard offers an in-depth analysis of electricity consumption patterns from 2009 to 2024, spotlighting the nation's ongoing transition from fossil fuels to renewable energy sources. It tracks key trends in energy generation, carbon emissions, and the integration of low-carbon technologies, providing insights into the evolution of the UK's energy landscape. The dashboard also examines the role of interconnectors, national demand, and policy changes, helping stakeholders understand the progress towards sustainability goals and the challenges that lie ahead in meeting future energy demands.",
                 )
             ),
             div(class = "section",
                 div(class = "text-section",
                     tags$h1("Exploring Key Research Questions & Identifying Stakeholders"),
                     tags$h3("Impact of Renewable Shift on Carbon Intensity"),
                     tags$p("How have the shifts in electricity consumption from fossil fuels to renewable energy sources influenced the carbon intensity of the UK's electricity grid from 2009 to 2024? What role do factors such as energy storage, interconnector flows, and demand play in modulating this relationship?")
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
             ),
             # Stakeholders and their roles
             tags$h3("Key Stakeholders"),
             tags$ul(
               tags$li("Government Regulators: Set policies and frameworks to achieve carbon reduction targets."),
               tags$li("Energy Providers: Manage energy generation and ensure a stable power supply."),
               tags$li("Grid Operators: Balance electricity supply and demand, integrating renewables and interconnectors."),
               tags$li("Consumers: Influence demand trends through consumption patterns and adoption of sustainable practices.")
             ),
             
             # Link to the next page (at the bottom right corner)
             # div(
             #   style = "position: absolute; bottom: -330px; right: 10px;",
             #   actionLink("toResearch", "Go to Research & Analysis", style = "font-size: 16px; color: #1b998b;")
             # )
             
           )),
  tabPanel("Research & Analysis",
           fluidPage(
             tags$h1("Energy Consumption Evolution"),
             tags$p("The National Demand visualisation tracks the trends in electricity consumption in the UK over the years. It highlights changes in overall demand, reflecting the evolving energy needs and shifts in energy policies. Users can explore these trends over time using interactive filters to view either monthly or yearly consumption, providing a deeper understanding of how national electricity usage has evolved in response to socio-economic, policy, and environmental factors.",
                    style="margin-right:50px;margin-bottom:30px;"),
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
                      tags$p("The visualisation reveals that national electricity demand has experienced both gradual declines and short-term fluctuations over the years. Major dips in demand coincide with key external events and government interventions. For example, the significant reduction in electricity demand between 2008 and 2010 aligns with the aftermath of the global financial crisis, which slowed industrial production and economic activity across the UK.
                             Additionally, during the COVID-19 pandemic (2020-2021), lockdowns and the temporary shutdown of non-essential businesses further decreased energy consumption as people remained at home, shifting patterns of electricity use.",style="margin-bottom:5px;"),
               ),
               column(12,
                      tags$h1("Sustainable Energy Transition",style="margin-top:50px;margin-bottom:30px;"),
                      tags$p("The Sustainable Energy Transition visualisation illustrates the shift in the UK’s energy mix over time, showing how different energy sources, such as renewables, low-carbon technologies, and fossil fuels, have contributed to electricity generation from 2009 to 2024."),
               ),
               tags$p(" ", style="margin-bottom:40px;margin-bottom:40px;"),
               fluidRow(
                 column(4,
                        wellPanel(
                          tags$h4("Interactive Filters"),
                          selectInput("timeResolutionStream", "Select Time Resolution:",
                                      choices = c("Monthly", "Yearly"))
                        )),
                 column(8, streamgraphOutput("energyStreamGraph")),
                 tags$p("", style="margin-bottom:40px;")
               ),
               
               tags$h2("Inference"),
               tags$p("The visualisation reveals several key trends. Over time, the proportion of renewable energy sources, such as wind, solar, and biomass, has steadily increased, reflecting the UK’s focus on decarbonization and sustainability. Wind energy, in particular, shows sharp increases, becoming a major contributor to the national grid. Meanwhile, fossil fuel-based energy sources demonstrate a declining trend, especially coal, which was almost entirely phased out in recent years."),
               tags$p("Periods of peak demand, visible as seasonal patterns, highlight the role of intermittent renewables and the growing dependence on energy storage technologies and interconnector imports to stabilize the grid. The visualisation also suggests that government interventions—such as the Carbon Price Floor policy and investments in renewable infrastructure—have played a crucial role in driving these transitions. This transformation underscores the UK’s journey toward meeting its net-zero emissions goals and maintaining energy security amid a changing climate and economy.", style="margin-bottom:20px;")
             ),
             
             # Interconnector Network Section
             tags$h1("UK Interconnector Network with Time-based Imports/Exports", style="margin-left:-20px;"),
             # Detailed description below the title
             tags$p("This interactive map visualizes the flow of electricity between the UK and its neighboring countries 
               over time. The map highlights the interconnector pipelines responsible for energy exchange. 
               Imports are represented by green-colored lines, while exports are marked in red. The thickness of 
               the lines remains constant to represent the infrastructure, but the opacity varies according to the 
               magnitude of the energy flows, giving users a quick sense of the volume being traded.", style="margin-left:-20px;"),
             
             tags$p("The energy network represented on the map allows the user to explore how energy imports and exports 
               have evolved between 2009 and 2024. This can be crucial for understanding energy dependency, 
               the dynamics of renewable energy, and the role of external markets in the UK’s energy mix. Hover 
               over each connection to view the exact power flow in megawatts (MW) for the selected year and 
               interconnector, giving insights into when the UK imports or exports the most energy across its borders.", style="margin-left:-20px;margin-bottom:20px;"),
             
             
             # Sidebar layout with slider
             sidebarLayout(
               sidebarPanel(
                 sliderInput(
                   inputId = "year",
                   label = "Select Year:",
                   min = 2009,
                   max = 2024,
                   value = 2009,
                   step = 1,
                   animate = animationOptions(interval = 1000, loop = TRUE)  # Animates the slider
                 ),
                 # New section explaining interaction
                 tags$h4("How to Interact with the Visualization", style="font-size:14px;"),
                 tags$p("1. Use the slider to navigate across different years and observe the changes in electricity flows.", style="font-size:14px;"),
                 tags$p("2. Hover over any interconnector line to see the exact flow in megawatts (MW), with the direction 
                of flow (import or export).", style="font-size:14px;"),
                 tags$p("3. The thickness of the pipelines represents the infrastructure, while the opacity of the colored lines 
                indicates the magnitude of flow—higher opacity indicates larger energy flows.", style="font-size:14px;"),
                 tags$p("4. You can zoom and pan on the map to explore connections in greater detail.", style="font-size:14px;")
               ),
               mainPanel(
                 leafletOutput("dnoMap", height = "700px")
               )
             ),
             tags$p("The interconnector flow visualisation highlights the evolution of electricity exchange between the UK and neighboring countries, showing how imports and exports help balance the grid during periods of high demand or surplus generation. Over the years, the UK’s reliance on imports has grown, especially during winters, with IFA and IFA2 interconnectors with France consistently delivering nuclear-generated electricity. Interconnectors like Nemo (Belgium) and BritNed (Netherlands) also diversify supply.", style="margin-top:40px;"),
             tags$p("The flow trends reflect renewable generation variability—the UK exports electricity during high wind output and imports during low output or grid stress. Post-Brexit energy policies have further influenced fluctuations in recent years. The growing interconnectivity underscores the importance of interconnectors for energy security and climate goals, promoting the exchange of low-carbon electricity across borders.", style="margin-bottom:40px;")
           )),
  tabPanel("Forecast & Insights",
           fluidPage(
             # Title of the page
             tags$h1("Forecast of Carbon Emissions, Renewables, and Low Carbon Sources", 
                     style = "margin-bottom:30px;"),
             
             # First Forecast Plot: Low Carbon, Renewables, and Demand
             fluidRow(
               column(12,
                      tags$h3("Forecast of Low Carbon, Renewables, and National Demand"),
                      tags$p("This visualization provides a forecast of key energy metrics for the next five years, showing low-carbon energy sources, renewable generation, and national electricity demand trends. Historical data is represented by solid lines, while the forecast is shown with dashed lines, accompanied by shaded confidence intervals to indicate uncertainty.",
                             style = "margin-bottom:30px;"),
                      plotlyOutput("forecastPlot1", height = "500px"),
               )
             ),
             
             # Second Forecast Plot: Carbon Intensity
             fluidRow(
               column(12,
                      tags$h3("Forecast of Carbon Intensity"),
                      plotlyOutput("forecastPlot2", height = "500px")
               )
             ),
             
             # Insights/Conclusion Section
             tags$h1("Key Takeaways", style = "margin-top:50px; margin-bottom:30px;"),
             
             fluidRow(
               column(12,
                      tags$p("Based on the presented trends and projections, the following key takeaways are derived:"),
                      tags$ul(
                        tags$li("The UK's shift towards renewable energy is expected to continue, driven by increased investments in solar, wind, and biomass sources."),
                        tags$li("Carbon emissions are projected to decline as fossil fuel dependency decreases, though challenges remain in ensuring grid stability."),
                        tags$li("Low-carbon technologies will play a critical role in meeting the UK’s net-zero target, requiring innovative solutions and policy support."),
                        tags$li("Interconnector networks will likely become more important to balance supply and demand, facilitating energy exchange with neighboring countries.")
                      ),
                      tags$p("The insights derived here not only highlight the progress made so far but also underscore the importance of sustained effort and collaboration 
                            across industries to achieve long-term energy sustainability.")
               )
             )
           )
  ),
  tabPanel("Data Sources",
           fluidPage(
             tags$h3("Data Sources and Acknowledgements"),
             tags$p("This application uses data from multiple sources which are continuously updated."),
             tags$ul(
               tags$li("National ESO Grid"),
               tags$li("Kaggle"),
               tags$li("Our World in Data"),
               tags$li("National Energy System Operator (NESO)")
             ),
             
             tags$h4("References"),
             tags$ol(
               tags$li("“Electricity System Operator | National Grid ESO.” Www.nationalgrideso.com, 
                       ", tags$a(href="https://www.nationalgrideso.com/", "www.nationalgrideso.com")),
               tags$li("“Historic GB Generation Mix | ESO.” Www.nationalgrideso.com, 
                       ", tags$a(href="https://www.nationalgrideso.com/data-portal/historic-generation-mix/historic_gb_generation_mix", 
                                 "www.nationalgrideso.com/data-portal/historic-generation-mix/historic_gb_generation_mix")),
               tags$li("Midoglu, Cise, et al. “SoccerMon: A Large-Scale Multivariate Soccer Athlete Health, Performance, 
                        and Position Monitoring Dataset.” Zenodo, 5 Sept. 2022, 
                        ", tags$a(href="https://zenodo.org/records/10033832", "zenodo.org/records/10033832"), ", https://doi.org/10.5281/zenodo.10033832. Accessed 24 Aug. 2024."),
               tags$li("Ritchie, Hannah, et al. “Energy.” Our World in Data, 2022, 
                       ", tags$a(href="https://ourworldindata.org/energy", "ourworldindata.org/energy")),
               tags$li("“Shiny- Welcome to Shiny.” Shiny.posit.co, 
                       ", tags$a(href="https://shiny.posit.co/r/getstarted/shiny-basics/lesson1/index.html", 
                                 "shiny.posit.co/r/getstarted/shiny-basics/lesson1/index.html")),
               tags$li("Araujo, M. (2024). Wind and Solar Surpass Fossil Fuels in the EU: A Milestone for Renewable Energy. Ymail.info. Available at: 
                        ", tags$a(href="https://ymail.info/wind-and-solar-surpass-fossil-fuels-in-the-eu-a-milestone-for-renewable-energy/", 
                                  "ymail.info/wind-and-solar-surpass-fossil-fuels-in-the-eu-a-milestone-for-renewable-energy/"), " [Accessed 30 Oct. 2024]."),
               tags$li("National Energy System Operator (NESO). (2024). Welcome to the NESO Data Portal | National Energy System Operator. 
                        Available at: 
                        ", tags$a(href="https://www.neso.energy/data-portal", "www.neso.energy/data-portal"))
             )
           ))
)