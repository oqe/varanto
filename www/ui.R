library(shiny)

rows = 1
#options(warn=-1)
options(shiny.trace=TRUE)

shinyUI(
  fluidPage(
    
    # OVERRIDE width=300px...
    # Number of annotations right behind the annotation label
    tags$head(
      tags$style(HTML("
        .shiny-input-container:not(.shiny-input-container-inline) {
          /*! width: 300px; */
          width: unset;
          /*! max-width: 100%; */
        }
      "))
    ),
    
    includeScript("variationsTextAreaBinding.js"),
    titlePanel("Varanto"),
    
    tabsetPanel(
      tabPanel("Input",
               fluidRow(
                 div(style="margin-top: 20px;",
                     column(6,
                            
                            radioButtons("input_method", strong("Input method:"), c("Paste" = "insertion", "Upload a file" = "upload"), inline=T),
                            conditionalPanel(
                              condition = "input.input_method == 'insertion'",
                              strong("Input variations:"),
                              actionButton("example", "Example variations"),
                              br(),
                              tags$textarea(id="variations_input", rows=3, class="returnTextArea form-control", style = 'width: 35%; margin-top: 8px;'),
                              br()
                            ),      
                            conditionalPanel(
                              condition = "input.input_method == 'upload'",
                              fileInput("upload", "Upload a text file with variation identifiers:", accept = "text/plain")
                            ),
                            
                            selectInput("back_set", label = strong("Background variation set:"), choices = setNames(back_set$id, paste0(back_set$description, " [", back_set$count, "]"))),
                            selectInput("filter_snps", label = strong("Filter variations by distance (bp):"), 
                                        choices = c("No filtering" = "NA", "1K" = "1000", "2K" = "2000", "5K" = "5000", "10K" = "10000", "20K" = "20000", "50K" = "50000"))
                     ),
                     column(6,
                            # SELECTINPUT
                            ###############
                            div(style = "margin-bottom: 8px;",
                                verticalLayout(
                                  selectInput("multiselectize_var", label="Variation annotations", choices=NULL, multiple=TRUE, selectize = FALSE, size=6),
                                  selectInput("multiselectize_gene", label="Gene annotations", choices=NULL, multiple=TRUE, selectize = FALSE, size=6)
                                )
                            )
                     )
                 )
               ),
               fluidRow(
                 column(12, align="center",
                        div(style="margin-bottom: 15px;",
                            actionButton("submit_ann1", "Submit")
                        )
                 )
               ),
               fluidRow(
                 column(12,
                        
                        # Summary information
                        ######################
                        wellPanel(style="width=100%;",
                                  div(
                                    div(style="inline=TRUE; display:inline-block; height:10px; padding-right: 30px;", textOutput('num_vars'), textOutput('num_filtered_vars')),
                                    div(style="inline=TRUE; display:inline-block; height:10px; padding-right: 30px;", textOutput('num_anns'), textOutput('num_associations'))
                                  )
                        ),
                        
                         hr(),
                         
                         # Annotation Data
                         ##################
                         verticalLayout(
                           textOutput('message_data'),
                            inputPanel(            
                              selectInput('max_columns', label = 'Maximum annotation columns to show:', choices = c(5L, 10L, 25L, 50L, 100L))
                            ),
                           
                           conditionalPanel(
                             condition = "output.variation_data!=null",
                             div(style = "margin-top: 15px; margin-bottom: 20px;",
                                 downloadButton('download_data', 'Download annotation data')
                             )
                           ),
                           dataTableOutput('variation_data')
                         )
                 )
               )
      ),
      
      tabPanel("Enrichment Analysis",
               
               conditionalPanel(
                 condition = "output.enrichment_data!=null",
                 div(style = "margin-bottom: 20px;",
                     downloadButton('download_enrichment', 'Download enrichment results')
                 )
               ),
               textOutput('message_noinput1'),
               dataTableOutput('enrichment_data')
               
      ),
      
      tabPanel('Heatmap',
               conditionalPanel(
                 condition = "output.plotlyheatmap_ui!=null",

                 inputPanel(
                   checkboxInput('autoheight', 'Auto plot height', TRUE),
                   numericInput('height', 'Height (px):', 900, min = 100, max = 10000, step = 100),
                   checkboxInput('autowidth', 'Auto plot width', TRUE),
                   numericInput('width', 'Width (px):', 1200, min = 100, max = 10000, step = 100),
                   numericInput('col_angle', 'Column labels angle:', 45, min = 0, max = 90, step = 5),            
                   #numericInput('margin_y', 'Row labels margin:', 5, min = 0, max = 1000, step = 1),
                   #numericInput('margin_x', 'Column labels margin:', 5, min = 0, max = 1000, step = 1),
                   numericInput('margin_left', 'Plot left margin:', 5, min = 0, max = 1000, step = 1),
                   numericInput('margin_right', 'Plot right margin:', 5, min = 0, max = 1000, step = 1),
                   numericInput('margin_top', 'Plot top margin:', 5, min = 0, max = 1000, step = 1),
                   numericInput('margin_bottom', 'Plot bottom margin:', 20, min = 0, max = 1000, step = 1),
                   # conditionalPanel(condition = "input.dendrograms == 'none' || input.dendrograms == 'column'",
                   #   numericInput('space_x', 'Row labels space', 0.25, min = 0, max = 12, step = 0.05)
                   # ),
                   # conditionalPanel(condition = "input.dendrograms == 'none' || input.dendrograms == 'row'",
                   #   numericInput('space_y', 'Column labels space', 0.25, min = 0, max = 12, step = 0.05)
                   # ),
                   # selectInput('dendrograms', label = "Dendrograms:", choices = c("None" = "none", "Annotations" = "column", "Variations" = "row", "Both" = "both")),
                   # selectInput('grid', 'Show grid', choices = c("No" = FALSE, "Yes" = TRUE)),
                   
                   checkboxInput('interactive_plotly', 'Interactive', TRUE)
                 ),
                 p(textOutput('message_heatmap'), align = "center"),
                 
                 div(style = "margin-top: 15px; padding-right: 15px;",
                     
                     actionButton("plot_heatmap","Plot"),
                     downloadButton('download_heatmap', 'Download heatmap')
                 )
               ),
               
               textOutput('message_noinput2'),
               uiOutput('plotlyheatmap_ui')
      ),
      
      tabPanel("Karyogram",
               textOutput('message_noinput3'),
               
               conditionalPanel(
                 condition = "output.variation_data!=null",
                 
                 plotOutput('karyogram_chromplot')
                )
      ),

      tabPanel("User Guide",
               tabPanel("Input", includeHTML("guide.txt"))
      ),
      
      tabPanel("About",
               tabPanel("About", includeHTML("about.txt")),
               tableOutput('version_info'),
               h3("R Session information:"),
               tags$pre(htmlOutput("sessionInfo"))
      )
    )
  )
)
