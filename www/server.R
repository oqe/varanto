#library(shiny)
#library(ggbio)
#library(GenomicRanges)

library(TxDb.Hsapiens.UCSC.hg38.knownGene)
library(chromPlot)

#require(Heatplus)
library(shiny)
library(plotly)
library(reshape2)
library(gplots)
library(stringr)
library(d3heatmap)
library(ggdendro)
library(gridBase)
library(RColorBrewer)
library(rvg)
library(ggiraph)
library(ggplot2)
library(dbplyr)
library(dplyr)

source('varanto_functions.R')

ann_counts = get_total_count_of_annotations_in_back_sets(global_conn)
print(ann_counts)

shinyServer(function(input, output, session) {    
  
  conn = get_connection(db, host=host, port=port, user=user, password=password)      
  first = TRUE
  
  select_deselect_all_var = FALSE
  select_deselect_all_gene = FALSE
  select_deselect_all_var_stop = FALSE
  select_deselect_all_gene_stop = FALSE
  
  reac_get_input_variations_not_filtered <- reactive({
    if (input$input_method == 'insertion') {      
      
      # DEBUG
      # print("PERUS INPUT VARIATIONS:")
      # print(input$variations_input)
      # print(strsplit(input$variations_input, '\n', fixed = TRUE)[[1]])
      # print("PROSESSOIDUT INPUT VARIATIONS:")
      # print(processTextInput(strsplit(input$variations_input, '\n', fixed = TRUE)[[1]]))

      
      get_variations_of_names_of_back_set(conn, processTextInput(strsplit(input$variations_input, '\n', fixed = TRUE)[[1]]), as.integer(input$back_set))
    } else if (input$input_method == 'upload') {
      if (is.null(input$upload)) {
        return (NULL)
      } else {
        get_variations_of_names_of_back_set(conn, paste(readLines(input$upload$datapath)), as.integer(input$back_set))
      }
    }
  })
  
  reac_get_input_variations <- reactive({
    if (is.null(reac_get_input_variations_not_filtered())) {
      return (NULL)
    }
    if (input$filter_snps == 'NA') {
      reac_get_input_variations_not_filtered()  
    } else {
      filter_variations(reac_get_input_variations_not_filtered(), as.integer(input$filter_snps))
    }
  })
  
  exampleObs <- observe ({
    input$example        
    if (first == TRUE) {
      first <<- FALSE
    } else {        
      session$sendInputMessage("variations_input", list(value=get_example_data()))      
    }
  })
  
  session$onSessionEnded(function() {
    exampleObs$suspend()
  })

  #print(ann_desc)
  
  # Needs to be called from ui.R
  ###############################
  for (i in 1:nrow(ann_desc)) {
    #DEBUG - REMOVE AFTER FIX
    #print("ANN_DESC")
    #print(ann_desc)
    
    local({      
      ii <- i      
      output[[paste0("ann_count_", ii)]] <- renderText({
        #DEBUG - REMOVE AFTER FIX
        # print(ii)
        # print(ann_counts)
        #print(colnames(ann_counts))
        
        if (as.character(ii) %in% colnames(ann_counts)) { 
          paste0('[', ann_counts[input$back_set, as.character(ii)], ']')
          
          #debug_anncounts <- paste0('[', ann_counts[input$back_set, as.character(ii)], ']')
        } else {
          '[0]'
          # DEBUG - REMOVE AFTER FIX
          #debug_anncounts <- "lol ei toimi"
        } 
      }) 
    })
  }
  
  observe({
    input$select_deselect_var_btn
    output$select_deselect_var_btn <- renderUI({
      actionButton("select_all_var", label = "Select all")
    })
  })
  
  observe ({
    input$select_all_var    
    if (select_deselect_all_var_stop) {      
      select_deselect_all_var_stop <<- FALSE
      return (NULL)
    } else {    
      select_deselect_all_var_stop <<- TRUE
    }
    
    for (i in var_ann_desc$id) {
      updateCheckboxInput(session, paste0("checkbox_ann_",i), value = select_deselect_all_var)      
    }
    if (select_deselect_all_var) {      
      label = "De-select all"
    } else {      
      label = "Select all"
    }
    select_deselect_all_var <<- !select_deselect_all_var    
    output$select_deselect_var_btn <- renderUI({actionButton('select_all_var', label = label)})
  })

  # SELECTINPUT
  ##############
  # Get updated (related to backset selection) annotation counts
  out_ann_counts <- reactive({
    
    # Output current counts by the selected background set
    ann_counts_perbackset <- ann_counts[input$back_set,]
    
    return(ann_counts_perbackset)
  })

  # GENE ANNOTATIONS - SELECT
  # renderUi (selectInput) (al)ready for ui.R
  output$ann_genes = renderUI({
    
    ann_gene_count <- as.numeric(gene_ann_desc$id)
    
    # retrieve all counts of annotations (per selected background set)
    all_counts_per_backset <- out_ann_counts()
    
    # # Debug
    # print("names(all_counts_per_backset):")
    # print(names(all_counts_per_backset))
    # print("ann_gene_count(ids):")
    # print(ann_gene_count)
    # print("match:")
    # print(match(ann_gene_count, names(all_counts_per_backset), nomatch=0))
    # print("which(names(all_counts_per_backset) %in% ann_gene_count)")
    # print(which(names(all_counts_per_backset) %in% ann_gene_count))
    # print(which(ann_gene_count %in% names(all_counts_per_backset)))
    
    # # Debug
    # print("str(all_counts_per_backset")
    # print(str(all_counts_per_backset))
    
    # Match gene annotation id with count named list (name = annotation id)
    # if id doesn't exist in count list give it value 0
    temp_counts = vector()
    for(i in 1:length(gene_ann_desc$id)){
      
      id_desc <- gene_ann_desc$id[i]
      
      # print("id_desc: ")
      # print(id_desc)
      
      if(id_desc %in% names(all_counts_per_backset)){
        id_count <- all_counts_per_backset[[as.character(id_desc)]] #all_counts_per_backset[[which(names(all_counts_per_backset) == id_desc]] 
        
        # print("id_count: ")
        # print(id_count)

        temp_counts[length(temp_counts) + 1] = paste0(" [", id_count, "]")
      } else {
        temp_counts[length(temp_counts) + 1] = paste0(" [0]")
      }
    }
    
    # # Debug
    # print("temp")
    # print(temp)
    
    # stich the name as description + count(per that description)
    names(ann_gene_count) <- paste0(gene_ann_desc$description, temp_counts)
  
    selectInput(
      'annotations_counts_gene',
      label="Gene annotations",
      choices=c("Select preferred gene annotations"="",ann_gene_count),
      multiple=TRUE,
      selectize = FALSE,
      size=6
    )
  })
  
  # VARIATION ANNOTATIONS - SELECT
  # renderUi (selectInput) (al)ready for ui.R
  output$ann_vars = renderUI({
    
    ann_var_count <- as.numeric(var_ann_desc$id)
    
    # retrieve all counts of annotations (per selected background set)
    all_counts_per_backset <- out_ann_counts()
    
    # Match gene annotation id with count named list (name = annotation id)
    # if id doesn't exist in count list give it value 0
    temp_counts = vector()
    for(i in 1:length(var_ann_desc$id)){
      id_desc <- var_ann_desc$id[i]
      if(id_desc %in% names(all_counts_per_backset)){
        id_count <- all_counts_per_backset[[as.character(id_desc)]]
        temp_counts[length(temp_counts) + 1] = paste0(" [", id_count, "]")
      } else {
        temp_counts[length(temp_counts) + 1] = paste0(" [0]")
      }
    }
    
    # stich the name as description + count(per that description)
    names(ann_var_count) <- paste0(var_ann_desc$description, temp_counts)
    
    selectInput(
      'annotations_counts_gene',
      label="Variation annotations",
      choices=c("Select prefered variation annotations"="",ann_var_count),
      multiple=TRUE,
      selectize = FALSE,
      size=6
    )
  })
  
  
  observe({
    ann_gene_count <- as.numeric(gene_ann_desc$id)
    
    # retrieve all counts of annotations (per selected background set)
    all_counts_per_backset <- out_ann_counts()
    
    # Match gene annotation id with count named list (name = annotation id)
    # if id doesn't exist in count list give it value 0
    temp_counts = vector()
    for(i in 1:length(gene_ann_desc$id)){
      id_desc <- gene_ann_desc$id[i]
      if(id_desc %in% names(all_counts_per_backset)){
        id_count <- all_counts_per_backset[[as.character(id_desc)]] #all_counts_per_backset[[which(names(all_counts_per_backset) == id_desc]] 
        temp_counts[length(temp_counts) + 1] = paste0(" [", id_count, "]")
      } else {
        temp_counts[length(temp_counts) + 1] = paste0(" [0]")
      }
    }
    
    # stich the name as description + count(per that description)
    names(ann_gene_count) <- paste0(gene_ann_desc$description, temp_counts)

    updateSelectInput(
      session,
      "multiselectize_gene",
      choices=c("Select preferred gene annotations (select multiple with CTRL+Mouse)"="",ann_gene_count)
    )
  })
  
  observe({
    ann_var_count <- as.numeric(var_ann_desc$id)
    
    # retrieve all counts of annotations (per selected background set)
    all_counts_per_backset <- out_ann_counts()
    
    # Match gene annotation id with count named list (name = annotation id)
    # if id doesn't exist in count list give it value 0
    temp_counts = vector()
    num_counts = vector()
    for(i in 1:length(var_ann_desc$id)){
      id_desc <- var_ann_desc$id[i]
      if(id_desc %in% names(all_counts_per_backset)){
        id_count <- all_counts_per_backset[[as.character(id_desc)]]
        temp_counts[length(temp_counts) + 1] = paste0(" [", id_count, "]")
        # numeric counts (for dataframe)
        num_counts[length(num_counts) + 1] <- id_count
      } else {
        temp_counts[length(temp_counts) + 1] = paste0(" [0]")
        # numeric counts (for dataframe)
        num_counts[length(num_counts) + 1] <- 0
      }
    }
    
    # help-dataframe for ordering/sorting displayed vector
    ann_df <- data.frame(ids=var_ann_desc$id, annotation_name=var_ann_desc$description, counts=num_counts)
    # extract Ens -names for sorting
    ens_df <- ann_df[grep("Ens", ann_df$annotation_name),]
    # sort by descending
    ens_df_tmp <- ens_df[order(ens_df$counts),]
    # remove "[Ens] Alleles"
    ens_df_tmp <- ens_df_tmp[grep("Alleles", ens_df_tmp$annotation_name, invert=TRUE),]
    # add rest of non "Ens" (GET-E)
    rest_df <- ann_df[grep("Ens", ann_df$annotation_name, invert=TRUE),]
    ordered_df <- rbind(ens_df_tmp, rest_df)
    # make named num (vector)
    ann_vec <- ordered_df$id
    # Add counts to names
    names(ann_vec) <- paste0(ordered_df$annotation_name, " [", ordered_df$counts,"]")
    
    # # stich the name as description + count(per that description)
    # names(ann_var_count) <- paste0(var_ann_desc$description, temp_counts)
    
    # remove Alleles, 1st value from list
    updateSelectInput(
      session,
      "multiselectize_var", #server=TRUE,
      choices=c("Select preferred variation annotations (select multiple with CTRL+Mouse)"="",ann_vec)
    )
  })
  
  # SELECTIZE DEMO - PRINT OUT SELECTION
  output$values_gene <- renderPrint({
    list(DEBUG_gene=input$multiselectize_gene)
  })
  output$values_var <- renderPrint({
    list(DEBUG_var=input$multiselectize_var)
  })

  output$values_ann <- renderPrint({
    list("DEBUG - Selected Annotations"=c(input$multiselectize_var, input$multiselectize_gene))
  })
  
##############################
  
  # updateSelectizeInput
  #######################
  reac_get_annotations <- reactive({
    
    # Act on clicking Submit button
    input$submit_ann1
    
    desc = vector()
    isolate({
      for (i in ann_desc$id) {
        
        if (i %in% input$multiselectize_gene || i %in% input$multiselectize_var)
          desc[length(desc) + 1] = i
      }
    })
    if (length(desc) > 0) {            
      get_annotations_of_desc_id_of_back_set(conn, as.integer(input$back_set), desc)
    } else {
      return (NULL)
    }    
  })    
  
  
  observe({
    input$select_deselect_gene_btn
    output$select_deselect_gene_btn <- renderUI({
      actionButton("select_all_gene", label = "Select all")
    })
  })
  
  observe ({
    input$select_all_gene    
    if (select_deselect_all_gene_stop) {      
      select_deselect_all_gene_stop <<- FALSE
      return (NULL)
    } else {    
      select_deselect_all_gene_stop <<- TRUE
    }
    
    for (i in gene_ann_desc$id) {
      updateCheckboxInput(session, paste0("checkbox_ann_",i), value = select_deselect_all_gene)
    }
    if (select_deselect_all_gene) {      
      label = "De-select all"
    } else {      
      label = "Select all"
    }
    select_deselect_all_gene <<- !select_deselect_all_gene
    output$select_deselect_gene_btn <- renderUI({actionButton('select_all_gene', label = label)})
  })
  
# # ORIGINAL DONT REMOVE
# 
#   reac_get_annotations <- reactive({    
#     input$submit_ann1
#     #input$submit_ann2 # removed from ui
#     #input$submit_ann3 # removed from ui
#     #find out which checkboxes are checked
#     desc = vector()
#     isolate({
#       for (i in ann_desc$id) {        
#         if (input[[paste0("checkbox_ann_",i)]])
#           desc[length(desc) + 1] = i
#       }
#     })
#     if (length(desc) > 0) {            
#       get_annotations_of_desc_id_of_back_set(conn, as.integer(input$back_set), desc)
#     } else {
#       return (NULL)
#     }    
#   })    
  
  reac_get_association_pairs <- reactive({
    if (is.null(reac_get_input_variations()) || is.null(reac_get_annotations())) {
      return (NULL)
    }
    get_association_pairs(conn,
                          reac_get_input_variations()$id, 
                          reac_get_annotations()$id)
  })
  
  output$num_vars <- renderText({
    if (is.null(reac_get_input_variations_not_filtered())) {
      variations = 0
    } else {
      variations = nrow(reac_get_input_variations_not_filtered())
    }
    
    paste0("Number of input variations in selected background set: ", variations)           
  })
  
  output$num_filtered_vars <- renderText({
    if (is.null(reac_get_input_variations())) {
      variations = 0
    } else {
      variations = nrow(reac_get_input_variations())
    }
    
    paste0("Number of input variations in selected background set (after filtering): ", variations)           
  })
  
  output$num_anns <- renderText({
    if (is.null(reac_get_annotations())) {
      annotations = 0
    } else {
      annotations = nrow(reac_get_annotations())
    }
    
    paste0("Number of unique annotation terms: ", annotations)
  })
  
  output$num_associations <- renderText({
    if (is.null(reac_get_association_pairs())) {
      pairs = 0
    } else {
      pairs = nrow(reac_get_association_pairs())
    }  
    
    paste0("Number of associations: ", pairs)
  })
  
  output$karyogram <- renderPlot({    
    if (is.null(reac_get_input_variations())) {
      ggplot(hg19) + layout_karyogram(cytoband = TRUE) +
        ggtitle("No variations selected!")
    } else {
      #dn <- keepSeqlevels(dn, paste0("chr", c(1:22, "X","Y")))
      dn <- GRanges(seqnames=paste0("chr",reac_get_input_variations()$chr),ranges=IRanges(start=reac_get_input_variations()$position, width=rep(1, nrow(reac_get_input_variations()))))
      #ggplot(hg19) + layout_karyogram(cytoband = TRUE) + layout_karyogram(dn, geom = "rect", color = "red", ylim=c(11,21))
      #biovizBase::isIdeogram(hg19)
      #print(head(hg19))
      
      #data(hg19Ideogram, package = "biovizBase")
      #seqlengths(dn) <- seqlengths(hg19Ideogram)[names(seqlengths(dn))]
      #dn <- keepSeqlevels(dn, paste0("chr", c(1:22, "X")))
      
      #autoplot(dn, layout="karyogram", cytoband=FALSE, color="red", coverage.col="red", coverage.fill="red")
      #layout_karyogram(hg19, cytoband = FALSE, fill = "white") +
      
      ggplot(hg19) + #layout_karyogram(cytoband = FALSE,) +
        layout_karyogram(hg19, cytoband = FALSE, fill = "white") +
        layout_karyogram(dn, geom = "rect", color = "#ff0000") +
        xlab("Chromosomal location (bp)") +
        ggtitle("Chromosomal locations of variations")
   
      }
  }, height = 800)
  
  
#   output$karyogram_ideo <- renderPlot({
#     
#     library(IdeoViz)
#     
#     if (is.null(reac_get_input_variations())) {
#     
#     } else {
#     
#       ideo <- getIdeo("hg38")
#       data("binned_fullGenome")
#       
#       dn <- GRanges(seqnames=paste0("chr",reac_get_input_variations()$chr),ranges=IRanges(start=reac_get_input_variations()$position, width=rep(1, nrow(reac_get_input_variations()))))
#       
#       plotOnIdeo(
#         chrom=seqlevels(binned_fullGenome),
#         ideo=ideo,
#         values_GR = dn,
#         value_cols = "value",
#         #plotType = "rect",
#         plotType = "seg_tracks",
#         col='orange', vertical=TRUE,
#         addScale = F,
#         plot_title = "Joo"
# #        cex.axis = 0.5,
# #        chromName_cex=0.6
#         )
#       
#     }
#   }, height = 800)
#
  # karyoploteR - R package
  output$karyogram_karyoploter <- renderPlot({
    
    library(karyoploteR) 
    
    if (is.null(reac_get_input_variations())) {
    
    } else {
      # Data
      dn <- GRanges(seqnames=paste0("chr",reac_get_input_variations()$chr),ranges=IRanges(start=reac_get_input_variations()$position, width=rep(1, nrow(reac_get_input_variations()))))
      
      print(head(dn))
      # Genome version of karyogram+coordinates
      kp <- plotKaryotype(genome="hg38")
      # Actual plot
      kpPlotMarkers(kp, data=dn)#, labels=genes$hgnc_symbol)  
    }
  }, height = 900)
  
  
  # chromPlot R-package
  output$karyogram_chromplot <- renderPlot({
    
    if(!is.null(reac_get_input_variations())) {
      txdb <- TxDb.Hsapiens.UCSC.hg38.knownGene
      library(GenomicFeatures)
      
      data(hg_gap)
      data(hg_cytoBandIdeo)
    
      # Data
      dn <- GRanges(seqnames=paste0("chr",reac_get_input_variations()$chr),ranges=IRanges(start=reac_get_input_variations()$position, width=rep(1, nrow(reac_get_input_variations()))))
      
      # chromPlot requires biomaRt which overrides function names (select which is used alot!)
      chromPlot(
        bands=hg_cytoBandIdeo,
        annot1=dn,
        gaps=hg_gap,
        title="Chromosomal locations of variations",
        scale.title="Location")
        # noHist=FALSE)
    }
  }, height = 900)
  
  
  output$message_enrichment <- renderText({
    if (is.null(reac_get_annotations())) {
      "No annotations selected!"
    }
  })
  
  output$message_noinput1 <- renderText({
    if(is.null(reac_get_input_variations())) {
      "No input: Please add input, select wanted annotation(s) and filtering from 'Input'-tab and press 'Submit'-button."
    }
  })
  output$message_noinput2 <- renderText({
    if(is.null(reac_get_input_variations())) {
      "No input: Please add input, select wanted annotation(s) and filtering from 'Input'-tab and press 'Submit'-button."
    }
  })
  
  reac_get_back_set <- reactive ({    
    filter(back_set, id == as.integer(input$back_set))
  })
  
  reac_get_total_variations <- reactive({
    reac_get_back_set()[['count']]
  })  
  
  reac_get_sparse_matrix <- reactive({
    if (is.null(reac_get_association_pairs())) {
      return (NULL)
    }
    get_sparse_matrix(reac_get_input_variations()$id, reac_get_annotations()$id, reac_get_association_pairs())
  })
  
  reac_get_samples_count <- reactive({
    if (is.null(reac_get_input_variations())) {
      0
    } else {
      nrow(reac_get_input_variations())
    }    
  })
  
  reac_get_odds_ratio <- reactive({
    if (is.null(reac_get_annotations())) {
      return (NULL)
    }    
    get_odds_ratio(reac_get_annotations(), reac_get_sparse_matrix(),
                   reac_get_samples_count(), reac_get_total_variations())
  })
  
  reac_get_overrepresentation_significance <- reactive({
    if (is.null(reac_get_odds_ratio())) {
      return (NULL)
    }    
    get_overrepresentation_significance(reac_get_odds_ratio(), reac_get_samples_count(), reac_get_total_variations())
  })
  
  reac_get_underrepresentation_significance <- reactive({
    if (is.null(reac_get_odds_ratio())) {
      return (NULL)
    }    
    get_underrepresentation_significance(reac_get_odds_ratio(), reac_get_samples_count(), reac_get_total_variations())
  })
  
  reac_get_enrichment_data <- reactive({    
    if (!is.null(reac_get_annotations())) {
      
      #if (input$overunder == 'under') {
      #enrichment_data = merge(reac_get_odds_ratio(), reac_get_underrepresentation_significance(), by='id')
      #} else if (input$overunder == 'over') {
      #enrichment_data = merge(reac_get_odds_ratio(), reac_get_overrepresentation_significance(), by='id')
      #} else if (input$overunder == 'both') {
      
      enrichment_data = merge(merge(reac_get_odds_ratio(), reac_get_underrepresentation_significance(), by='id'), 
                              reac_get_overrepresentation_significance(), by='id')
      
      #remove not important columns and combine labels with their attributes names
      enrichment_data$id = NULL
      enrichment_data$ann_id = NULL
      enrichment_data$back_set_id = NULL
      enrichment_data$count = NULL
      ann_desc2name = character()
      ann_desc2name[ann_desc$id] = ann_desc$description
      enrichment_data$label = paste0(ann_desc2name[enrichment_data$annotation_description_id], ": ", enrichment_data$label)
      enrichment_data$annotation_description_id = NULL
      
      #order data
      #if (input$overunder == 'both' || input$overunder == 'over') {
      enrichment_data = enrichment_data[with(enrichment_data, order(enrichment_data$pvalue_over, enrichment_data$label)),]
      #} else if (input$overunder == 'under') {
      #enrichment_data = enrichment_data[with(enrichment_data, order(enrichment_data$pvalue_under, enrichment_data$label)),]
      #}
      #use readable names for headers
      common_headers = c('Label', 'Description', 'Observed', 'Expected', 'Odds ratio')
      #if (input$overunder == 'both') {
      enrichment_data = enrichment_data[c(colnames(enrichment_data)[1:5], "pvalue_under", "pvalue_under_fdr", "pvalue_over", "pvalue_over_fdr")]      
      colnames(enrichment_data) = c(common_headers, "Under P", 'Under P-FDR',
                                    "Over P", "Over P-FDR")
      
      #} else if (input$overunder == 'over') {      
      #  enrichment_data = enrichment_data[c(colnames(enrichment_data)[1:5], "pvalue_over_fdr", "pvalue_over")]      
      #  colnames(enrichment_data) = c(common_headers, "Adjusted overrepresentation P-value (FDR)", "Overrepresentation P-value")      
      #} else if (input$overunder == 'under') {
      #  enrichment_data = enrichment_data[c(colnames(enrichment_data)[1:5], "pvalue_under_fdr", "pvalue_under")]
      #  colnames(enrichment_data) = c(common_headers, 'Adjusted underrepresentation P-value (FDR)', "Underrepresentation P-value")
      #}
      
      enrichment_data
    }
    
  })  
  
  output$download_enrichment <- downloadHandler(
    filename = function () {
      paste0('enrichment_data-', Sys.time(), '.csv')
    },
    content = function(file) {
      if (is.null(reac_get_annotations())) {
        write.csv(NULL, file)
      } else {     
        #order and download
        write.csv(reac_get_enrichment_data(), file, row.names=FALSE)      
      }
    }
  )
  
  output$enrichment_data <- renderDataTable({    
    as.data.frame(reac_get_enrichment_data()) #needed to wrap it with as.data.frame because of error when sort (bug in shiny: https://github.com/rstudio/shiny/issues/636)    
  }, escape = FALSE)
  
  output$message_heatmap <- renderText({
    if (is.null(reac_get_association_pairs())) {
      "No associations found."
    }
  })  
  
  reac_get_contingency_table <- reactive({
    get_contingency_table(reac_get_input_variations(), reac_get_annotations(), ann_desc, reac_get_association_pairs())
  })

  #####################
  
  output$heatmap_ui <- renderUI({
    plotOutput("heatmap", height = input$height)    
  })
  
  renderHeatmap <- function() {
    if (input$dendrograms == 'both') {      
      lwid = c(1.5,4) #default lhei in heatmap.2
      lhei = c(1.5,4) #default lhei in heatmap.2
    } else if (input$dendrograms == 'row') {      
      lwid = c(1.5,4)
      lhei = c(input$space_y,4)
    } else if (input$dendrograms == 'column') {      
      lwid = c(input$space_x,4)
      lhei = c(1.5,4)
    } else if (input$dendrograms == 'none') {      
      lwid = c(input$space_x,4)
      lhei = c(input$space_y,4)      
    }
    if (input$grid) {
      colsep = 0:ncol(reac_get_contingency_table())
      rowsep = 0:nrow(reac_get_contingency_table())      
    } else {
      colsep = c(0, ncol(reac_get_contingency_table()))
      rowsep = c(0, nrow(reac_get_contingency_table()))
    }
    
    #heatmap.2(reac_get_contingency_table(), 
    d3heatmap(reac_get_contingency_table(), 
              margins = c(input$margin_x, input$margin_y),               
              col = c('white', 'blue'),
              breaks=c(0,0.5,1),
              dendrogram = input$dendrograms,
              colsep = colsep,
              rowsep = rowsep,
              sepcolor = "grey",
              sepwidth = c(0.01,0.01),
              trace = "none",
              srtCol = input$col_angle,              
              lwid = lwid,
              lhei = lhei,
              key=FALSE)  
  }
  
  output$download_heatmap <- downloadHandler(
    filename = function () {      
      paste0('heatmap-', Sys.time(), '.pdf')
    },
    content = function(file) {
      
      # pdf(file=file)
      # p <- renderPlotlyHeatmap()
      # print(p)
      # dev.off()
      
      if (is.null(reac_get_contingency_table())) {
        pdf(file=file)
        #ggsave(file, plot=renderPlotlyHeatmap(), device="pdf")
        p <- renderPlotlyHeatmap()
        print(p)
      } else {
        #order and download
        pdf_width = ncol(reac_get_contingency_table()) / 7
        if (pdf_width < 14) {
          pdf_width = 14
        }
        pdf_height = nrow(reac_get_contingency_table()) / 7
        if (pdf_height < 14) {
          pdf_height = 14
        }
        #ggsave(file, plot=renderPlotlyHeatmap(), device="pdf", width=pdf_width, height=pdf_height)
        pdf(file=file, width = pdf_width, height = pdf_height)
        p <- renderPlotlyHeatmap()
        print(p)
      }
      dev.off()
      #unlink(file)
    }
    
  )
  
  output$heatmap <- renderPlot({        
    if (is.null(reac_get_contingency_table())) {
      return(NULL)
    }    
    renderHeatmap()
  }) 
  
  #########################################################
  
  output$plotlyheatmap_ui <- renderUI({
    # actionButton
    input$plot_heatmap
    
    tmp <- reac_get_contingency_table()
    
    if(!is.null(tmp)){

            # Check data dimensions -> interactive plot or not
      dimensions <- nrow(tmp) * ncol(tmp)

      if(dimensions > 100*1000 | input$interactive_plotly  == FALSE) {
        # "Too big" dimensions for plot
        if(dimensions > 100*1000){
          output$message_heatmap <- renderText({ "Rendered static heatmap due to large data dimensions" })
          
          #ggplot_heatmap <- rederPlot({ plot(renderPlotlyHeatmap()) })
          plotOutput("ggplot_heatmap", height = input$height, width=input$width)
          
        # Deselecting interactive checkbox
        } else {
          output$message_heatmap <- renderText({ "Rendered static heatmap due interactive deselect" })
          
          #ggplot_heatmap <- rederPlot({ plot(renderPlotlyHeatmap()) })
          plotOutput("ggplot_heatmap", height = input$height, width=input$width)
        }
      } else {
        # Rendering heatmap/ui
        output$message_heatmap <- renderText({ "" })
        
        plotlyOutput("heatmap_plotly", height = input$height, width=input$width)
      }
      
    }
    
  })
  
  output$ggplot_heatmap <- renderPlot({ 
    
    if (is.null(reac_get_contingency_table())) {
      return(NULL)
    }
    
    # Progress indicator
    progress <- Progress$new(session, min=1, max=2)
    on.exit(progress$close())
    # Initial progress message
    progress$set(message = 'Plot',
                 detail = 'Generating static plot')
    
    # update progress
    progress$set(detail = "Calculating static plot [1/2]", value = 1)
    
    # Actual plotting function (ggplot)
    gg <- renderPlotlyHeatmap()
    
    # update progress
    progress$set(detail = "Rendering plot [2/2]", value = 2)
    
    plot(gg)
  })
  
  output$heatmap_plotly <- renderPlotly({
    
    if (is.null(reac_get_contingency_table())) {
      return(NULL)
    }
    
    # Progress indicator
    progress <- Progress$new(session, min=1, max=3)
    on.exit(progress$close())
    # Initial progress message
    progress$set(message = 'Plot',
                 detail = 'Generating interactive plot')
    plotOutput("ggplot_heatmap", height = input$height, width=input$width)
    # update progress
    progress$set(detail = "Calculating interactive plot [1/3]", value = 1)
    
    # Actual plotting function (ggplot)
    gg <- renderPlotlyHeatmap()
  
    # update progress
    progress$set(detail = "Converting to plotly (longest stage) [2/3]", value = 2)
    
    # Convert ggplot to plotly
    ggp <- ggplotly(gg)
    
    # update progress
    progress$set(detail = "Rendering plot [3/3]", value = 3)
    
    ggp
    
  })
  
  
  
  renderPlotlyHeatmap <- function(){  
    
    # # grid, dendrogram disabled from ui.R
    # ######################################
    # 
    #   if (input$dendrograms == 'both') {      
    #     lwid = c(1.5,4) #default lhei in heatmap.2
    #     lhei = c(1.5,4) #default lhei in heatmap.2
    #   } else if (input$dendrograms == 'row') {      
    #     lwid = c(1.5,4)
    #     lhei = c(input$space_y,4)
    #   } else if (input$dendrograms == 'column') {      
    #     lwid = c(input$space_x,4)
    #     lhei = c(1.5,4)
    #   } else if (input$dendrograms == 'none') {      
    #     lwid = c(input$space_x,4)
    #     lhei = c(input$space_y,4)      
    #   }
    #   if (input$grid) {
    #     colsep = 0:ncol(reac_get_contingency_table())
    #     rowsep = 0:nrow(reac_get_contingency_table())      
    #   } else {
    #     colsep = c(0, ncol(reac_get_contingency_table()))
    #     rowsep = c(0, nrow(reac_get_contingency_table()))
    #   }
    
      margin_p <- list(
        l=input$margin_left,
        r=input$margin_right,
        b=input$margin_bottom,
        t=input$margin_top,
        pad=4
      )
      
      tmp <- reac_get_contingency_table()
      datamat <- as.matrix(reac_get_contingency_table())
      
      rownames(datamat) <- dimnames(tmp)$var_name
      colnames(datamat) <- dimnames(tmp)$ann_label
      
      # hclust ordering of rows and columns
      dd.col <- as.dendrogram(hclust(dist(datamat)))
      dd.row <- as.dendrogram(hclust(dist(t(datamat))))
      col.ord <- order.dendrogram(dd.col)
      row.ord <- order.dendrogram(dd.row)
      
      datamat.clust.ord <- datamat[col.ord,row.ord]
      
      #print(head(colnames(datamat)[col.ord]))
      #print(head(rownames(datamat)[row.ord]))
  
      # TODO:
      ## string width as interactive input
      ## all margins as interactive input
      ## font size as input
      ## geom_tile size as input
      ## angle 0 enables auto wrapping
      ##
      
      # Debugging
  #     print(head(t(df)))
  #     print(rownames(df))
  #     print(colnames(df))
  #     print(head(melt(t(df))))
  # 
      
      # auto wrapping of long annotation labels (x-axis)
      if(input$col_angle == 0){
        newx <- str_wrap(colnames(datamat), width=10)  
      } else {
        newx <- colnames(datamat)  
      }
      # colors for heatmap tiles
      hm.colors <- colorRampPalette(c("white", "lightblue"))(2)
  
      melted <- melt(datamat)
      #print(melted)
      melted[,"value"] <- factor(melted[,"value"])
  
      # auto wrapping of long labels
      newx <- str_wrap(colnames(datamat), width=10)
      
      # longest annotation string
      labels <- as.vector(unique(melted$ann_label))
      length.vec <- lapply(as.vector(unique(melted$ann_label)), nchar)
      longest.index <- which.max(length.vec)
      longest.ann.len <- nchar(labels[longest.index])
      
      gg <- ggplot(melted, aes(x=ann_label, y=var_name)) +
        geom_tile(aes(fill=value), color="grey40")+#, size=12, width=.9, height=.9) +
        scale_fill_manual(values=c("white","lightblue")) +
        theme_bw() +
        theme(axis.text.x = element_text(angle = input$col_angle, hjust = 1, vjust=1), #margin=margin(10,0,10,10)),
              axis.title.x=element_blank(), axis.title.y=element_blank()) + 
        #scale_x_discrete(labels=function(x) str_wrap(x, width=10)) +
        theme(plot.margin = unit(c(input$margin_top, input$margin_left, input$margin_bottom, input$margin_right), "mm"),
              legend.position='none') +
        coord_equal()
        
      # grid, dendrogram disabled from ui.R
      ######################################
        # add axis lines
        #theme(#axis.line.x = element_line(color="black", size = 1),
              #axis.line.y = element_line(color="black", size = 1),
         #     panel.grid.minor = element_line(colour="black", size=1))#,
              #panel.grid.major = element_line(colour = "black", size=1))
  
      
      # Auto height enabled, approximate height from rows etc.
      if(input$autoheight){
        newheight <- 30*length(unique(melted$var_name))+input$margin_top+input$margin_bottom

        # check min. height
        if(newheight < 400){
          newheight <- 400
        }
        print("new height:")
        print(newheight)
        
        myheight=newheight
      # Auto height disabled, take height from textInput
      } else {
        myheight=input$height
      }

      # Auto width checkbox chosen
      if(input$autowidth){
        newwidth <- 30*length(unique(melted$ann_label)) + 20
        
        # check min. height
        if(newwidth < 400){
          newwidth <- 400
        }
        print("new width:")
        print(newwidth)
        
        mywidth=newwidth
        
      # auto width disabled, take height from textInput
      } else {
        mywidth=input$width
      }

      updateTextInput(session, "height", value=myheight)
      updateTextInput(session, "width", value=mywidth)

      gg
  }
  
  
  output$ggheatmap_ui <- renderUI({
    ggiraphOutput("heatmap_ggplot", height = input$height)
  })
  
  output$heatmap_ggplot <- renderggiraph({
    if (is.null(reac_get_contingency_table())) {
      return(NULL)
    }    
    renderGGHeatmap()    
  })
  
  renderGGHeatmap <- function(){  
    
    if (input$dendrograms == 'both') {      
      lwid = c(1.5,4) #default lhei in heatmap.2
      lhei = c(1.5,4) #default lhei in heatmap.2
    } else if (input$dendrograms == 'row') {      
      lwid = c(1.5,4)
      lhei = c(input$space_y,4)
    } else if (input$dendrograms == 'column') {      
      lwid = c(input$space_x,4)
      lhei = c(1.5,4)
    } else if (input$dendrograms == 'none') {      
      lwid = c(input$space_x,4)
      lhei = c(input$space_y,4)      
    }
    if (input$grid) {
      colsep = 0:ncol(reac_get_contingency_table())
      rowsep = 0:nrow(reac_get_contingency_table())      
    } else {
      colsep = c(0, ncol(reac_get_contingency_table()))
      rowsep = c(0, nrow(reac_get_contingency_table()))
    }
    
    margin_p <- list(
      l=input$margin_left,
      r=input$margin_right,
      b=input$margin_bottom,
      t=input$margin_top,
      pad=4
    )
    
    tmp <- reac_get_contingency_table()
    datamat <- as.matrix(reac_get_contingency_table())
    
    rownames(datamat) <- dimnames(tmp)$var_name
    colnames(datamat) <- dimnames(tmp)$ann_label
    
    # longest annotation string
    length.vec <- lapply(colnames(datamat),nchar)
    longest.index <- which.max(length.vec)
    longest.ann.len <- nchar(length.vec[longest.index])
    
    # hclust ordering of rows and columns
    dd.col <- as.dendrogram(hclust(dist(datamat)))
    dd.row <- as.dendrogram(hclust(dist(t(datamat))))
    col.ord <- order.dendrogram(dd.col)
    row.ord <- order.dendrogram(dd.row)
    
    datamat.clust.ord <- datamat[col.ord,row.ord]
    
    print(head(colnames(datamat)[col.ord]))
    print(head(rownames(datamat)[row.ord]))
    
    # ggplot2 -> plotly
    ####################
    
    # TODO:
    ## string width as interactive input
    ## all margins as interactive input
    ## font size as input
    ## geom_tile size as input
    ## angle 0 enables auto wrapping
    ##
    
    # Debugging

    # auto wrapping of long annotation labels (x-axis)
    if(input$col_angle == 0){
      newx <- str_wrap(colnames(df), width=10)  
    } else {
      newx <- colnames(df)  
    }
    # colors for heatmap tiles
    hm.colors <- colorRampPalette(c("white", "lightblue"))(2)
    
    #nColor <- length(unique(df))
    #class(df) <- "character"
    
#       p <- df %>%
#         melt() %>%
#         ggplot(aes(x=ann_label, y=var_name, fill=value)) +
#         geom_tile() +
#           #geom_tile(aes(fill=value), size=12) +
#         #scale_fill_manual(values=hm.colors, name="Value") +
#         #scale_fill_manual(values=c("white","lightblue"), name="Value") +
#         #scale_fill_manual(values=brewer.pal(nColor,"Blues")) +
#         theme_bw() +
#         theme(axis.text.x = element_text(angle = input$col_angle,
#                                          hjust = 0,
#                                          vjust=1),
#               axis.title.x=element_blank(),
#               axis.title.y=element_blank()) +
#           #scale_x_discrete(labels=newx) +
#         theme(plot.margin = unit(c(input$margin_top, input$margin_left, input$margin_bottom, input$margin_right), "mm")) +
#         guides(colour=FALSE)
#       
#         #   # Working with plotly interactive mistakes
#         #    gg <- ggplot(melted, aes(x=ann_label, y=var_name)) +
#         #       geom_tile(aes(fill=value), size=12) +
#         #       scale_fill_manual(values=c("white","lightblue")) +
#         #       theme_bw() +
#         #       theme(axis.text.x = element_text(angle = input$col_angle, hjust = 0, vjust=0, margin=margin(10,10,10,10)),
#         #             axis.title.x=element_blank(), axis.title.y=element_blank()) +
#         #       scale_x_discrete(labels=function(x) str_wrap(x, width=10)) +
#         #       theme(plot.margin = unit(c(input$margin_y, input$margin_x, input$margin_y, input$margin_x), "mm"))
#   
#       gp <- ggplotly(p) %>%
#         layout(showlegend=F)
#       
#       gp
#       
    melted <- melt(datamat)
    melted[,"value"] <- factor(melted[,"value"])
    
    # auto wrapping of long labels
    newx <- str_wrap(colnames(datamat), width=10)
    
    gg <- ggplot(melted, aes(x=ann_label, y=var_name)) +
      geom_tile(aes(fill=value), size=12) +
      scale_fill_manual(values=c("white","lightblue")) #+
#       theme_bw() +
#       theme(axis.text.x = element_text(angle = input$col_angle,
#                                        hjust = 0,
#                                        vjust=1),
#                                        #margin=margin(10,10,10,10)),
#             axis.title.x=element_blank(), axis.title.y=element_blank())
      #scale_x_discrete(labels=function(x) str_wrap(x, width=10)) +
      #theme(plot.margin = unit(c(input$margin_y, input$margin_x, input$margin_y, input$margin_x), "mm")) +
    gg + geom_rect_interactive()
    
    #gg
    
    mytheme_main <- theme( panel.background = element_blank(), 
                           panel.grid.major = element_line(colour = "#dddddd"), 
                           axis.ticks = element_line(colour = "#dddddd") )
    
    mytheme_map <- theme(
      panel.background = element_blank(), axis.title.x = element_blank(),
      axis.text = element_blank(), axis.line.x = element_blank(),
      axis.line.y = element_blank(), axis.title.y = element_blank(),
      axis.ticks.x = element_blank(), axis.ticks.y = element_blank() )
    
    ggiraph(code={print(gg + mytheme_main)}, width=10, height=10)
  
  }
  ################################################################
  output$d3heatmap_ui <- renderUI({
    d3heatmapOutput("heatmapD3", height = input$height)    
  })
  
  output$heatmapD3 <- renderD3heatmap({
    if (is.null(reac_get_contingency_table())) {
      return(NULL)
    }    
    renderD3Heatmap()    
  })
  
  renderD3Heatmap <- function() {
    if (input$dendrograms == 'both') {      
      lwid = c(1.5,4) #default lhei in heatmap.2
      lhei = c(1.5,4) #default lhei in heatmap.2
    } else if (input$dendrograms == 'row') {      
      lwid = c(1.5,4)
      lhei = c(input$space_y,4)
    } else if (input$dendrograms == 'column') {      
      lwid = c(input$space_x,4)
      lhei = c(1.5,4)
    } else if (input$dendrograms == 'none') {      
      lwid = c(input$space_x,4)
      lhei = c(input$space_y,4)      
    }
    if (input$grid) {
      colsep = 0:ncol(reac_get_contingency_table())
      rowsep = 0:nrow(reac_get_contingency_table())      
    } else {
      colsep = c(0, ncol(reac_get_contingency_table()))
      rowsep = c(0, nrow(reac_get_contingency_table()))
    }
    
    #heatmap.2(reac_get_contingency_table(), 
    d3heatmap(reac_get_contingency_table(), 
              margins = c(input$margin_x, input$margin_y),               
              col = c('white', 'blue'),
              breaks=c(0,0.5,1),
              dendrogram = input$dendrograms,
              #colsep = colsep, #not in d3heatmap
              #rowsep = rowsep, #not in d3heatmap
              sepcolor = "grey", #not in d3heatmap
              sepwidth = c(0.01,0.01), #not in d3heatmap
              trace = "none", #not in d3heatmap
              srtCol = input$col_angle,              
              #lwid = lwid, #not in d3heatmap
              #lhei = lhei, #not in d3heatmap
              key=FALSE,
              xaxis_height = input$margin_top,
              yaxis_width = input$margin_right,
              xaxis_font_size = 10,
              yaxis_font_size = 10,
              show_grid=input$grid)
  }
  
  output$download_heatmapd3 <- downloadHandler(
    filename = function () {      
      paste0('heatmap-', Sys.time(), '.pdf')
    },
    content = function(file) {
      if (is.null(reac_get_contingency_table())) {
        pdf(file=file)
      } else {
        #order and download
        pdf_width = ncol(reac_get_contingency_table()) / 7
        if (pdf_width < 14) {
          pdf_width = 14
        }
        pdf_height = nrow(reac_get_contingency_table()) / 7
        if (pdf_height < 14) {
          pdf_height = 14
        }
        pdf(file=file, width = pdf_width, height = pdf_height)
        renderHeatmap()
        dev.off()      
      }
    }
  )

  #####################################################
  
  output$tableoutputtest <- renderText({
    attr(reac_get_contingency_table(), which="ann_label")
    
  })
  
  output$trendPlot <- renderPlotly({
    # size of the bins depend on the input 'bins'
    size <- (maxx - minx) / input$bins
    
    # a simple histogram of movie ratings
    p <- plot_ly(movies, x = rating, autobinx = F, type = "histogram",
                 xbins = list(start = minx, end = maxx, size = size))
    # style the xaxis
    layout(p, xaxis = list(title = "Ratings", range = c(minx, maxx), autorange = F,
                           autotick = F, tick0 = minx, dtick = size))
  })
  
  output$message_data <- renderText({
    if (is.null(reac_get_input_variations())) {
      "No valid variation names given."
    }
  })
  
  reac_get_variation_binary_data <- reactive({
    if (is.null(reac_get_input_variations())) {
      return (NULL)
    }
    get_variation_binary_data(reac_get_input_variations(), reac_get_annotations(), ann_desc, reac_get_sparse_matrix(), ": ", annotation.n=as.integer(input$max_columns))
  })
  reac_get_variation_binary_data_download <- reactive({
    if (is.null(reac_get_input_variations())) {
      return (NULL)
    }
    get_variation_binary_data(reac_get_input_variations(), reac_get_annotations(), ann_desc, reac_get_sparse_matrix(), ": ", annotation.n=NULL)
  })
  
  get_variation_data_to_presentation <- function(variation_binary_data) {    
    variation_binary_data$id = NULL
    if (length(colnames(variation_binary_data)) == 5) {
      colnames(variation_binary_data) = c('Name', 'Strand', 'Position', 'Allele', 'Chromosome')
    } else {      
      colnames(variation_binary_data) = c('Name', 'Strand', 'Position', 'Allele', 'Chromosome', colnames(variation_binary_data)[6:length(colnames(variation_binary_data))])
    }
    return(variation_binary_data)
  }
  
  output$download_data <- downloadHandler(
    filename = function () {
      paste0('data-', Sys.time(), '.csv')
    },
    content = function(file) {
      if (is.null(reac_get_variation_binary_data())) {
        write.csv(NULL, file)
      } else {
        variation_binary_data = reac_get_variation_binary_data_download()
        write.csv(get_variation_data_to_presentation(variation_binary_data), file, row.names=FALSE)
      }
    }
  )  
  
  output$variation_data <- renderDataTable({
    if (is.null(reac_get_variation_binary_data())) {
      return (NULL)
    }
    annotations = reac_get_annotations()   

    # MAX COLUMNS disabled from ui.R
     if (length(annotations) > 0 && nrow(annotations) > as.integer(input$max_columns)) {      
       annotations = annotations[1:as.integer(input$max_columns),]      
     }
    variation_binary_data = reac_get_variation_binary_data()
    
    as.data.frame(get_variation_data_to_presentation(variation_binary_data)) #needed to wrap it with as.data.frame because of error when sort (bug in shiny: https://github.com/rstudio/shiny/issues/636)
  })
  
  # simple table (renderTable)
  output$version_info <- renderTable({
      version_matrix <- matrix(c("Primary data", "Ensembl", "Ens", "89 (GRCh38.p10)", "<a href=\"http://may2017.archive.ensembl.org/Homo_sapiens/Info/Annotation\">http://may2017.archive.ensembl.org/Homo_sapiens/Info/Annotation</a>", "16 June 2017",
                                 "Variation annotations", "GET-Evidence", "GET-E", "latest available (18 June 2017)", "<a href=\"http://evidence.pgp-hms.org/about\">http://evidence.pgp-hms.org/about</a>", "18 June 2017",
                                 "Gene annotations", "Molecular Signature Database", "MSigDB", "6.0", "<a href=\"http://software.broadinstitute.org/gsea/msigdb\">http://software.broadinstitute.org/gsea/msigdb</a>", "15 June 2017",
                                 "Background sets", "UCSC", "", "Golden Path hg19 - snpArray*[array name]", "<a href=\"http://hgdownload.cse.ucsc.edu/goldenPath/hg19/database/\">http://hgdownload.cse.ucsc.edu/goldenPath/hg19/database/</a>", "16 June 2017"
                                 )
                               ,nrow=4, ncol=6, byrow=TRUE)
      colnames(version_matrix) <- c("Data", "Source name", "Acronym", "Version","Source","Updated to Varanto")
      version_matrix
  }, sanitize.text.function=function(x) x)
  
  # sessionInfo printout
  output$sessionInfo <- renderPrint({
    capture.output(sessionInfo())
  })

})
