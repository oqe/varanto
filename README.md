# Varanto

Varanto is an online database and tool for annotating human genetic variations using various annotation data sources. Varanto can be used to query a set of input variations, retrieve associated annotations and to visualize and analyze the results.

Varanto has been developed by the Bioinformatics Center at the University of Eastern Finland, Kuopio Finland.

Varanto web application is available to use at [http://bioinformatics.uef.fi/varanto/](http://bioinformatics.uef.fi/varanto/)

Varanto is developed using R and Shiny web framework.

Local installation and deployment instructions are on INSTRUCTIONS.md file.

## Varanto web app architecture and user interface

User input can be given as space separated short variation identifiers and/or as specific genomic locations (<chromosome>:<start position>). For example "rs53576 11:66560624 rs7412". User may select **Background variation set** to limit SNPs that are only on a specific SNP-array, select possible distance filtering, select preferred variation and gene level annotations. **Choosing many large annotations will increase the compute time for calculating results.**

Annotation Data Table is generated on the main page according to user input and selections. Subsequent user interface tabs and their content for Enrichment Analysis, Heatmap and Karyogram are generated from annotation data table. Varanto is dependent on publicly available data resources from Ensembl, MSigDB and GET-Evidence. Before deploying Varanto on a server or on a local machine selected parts of these resources need to be downloaded and prepared for import.

![Varanto web app architecture and user interface](/documents/varanto_architecture_900x747.png)
