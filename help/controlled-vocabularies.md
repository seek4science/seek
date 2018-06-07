---
title: Controlled Vocabularies and Ontologies
layout: page
redirect_from: "/controlled-vocabularies.html"
---

# Controlled Vocabularies and Ontologies

**This guide refers to SEEK, but is also relevant for [FAIRDOMHUB](https://www.fairdomhub.org/), which is an instance of SEEK.**

We recommend SEEK users use identifiers from public databases and terms from community ontologies wherever possible when describing and annotating data and models. The following table shows the resources available for annotation by biological object category. These represent the most commonly used within System Biology.

## Contributing 
SEEK documentation is a community driven activity, and we are always looking to expand. If you have any modifications you want to make to the list please send requests, or feedback to <community@fair-dom.org>.

<table>
	<tbody><tr>
		<th>Entity </th>
		<th>Resource </th>
		<th>Example ID </th>
		<th>Database <span class="caps">URL</span> </th>
		<th><span class="caps">MIRIAM</span> <span class="caps">URN</span> </th>
	</tr>
	<tr>
		<td> Protein </td>
		<td> <span class="caps">UNIPROT</span> </td>
		<td> <a href="http://www.uniprot.org/uniprot/p23470">P23470</a> </td>
		<td> <a href="http://www.ebi.uniprot.org">http://www.ebi.uniprot.org</a> </td>
		<td> urn:miriam:uniprot </td>
	</tr>
	<tr>
		<td>Chemical </td>
		<td> ChEBI </td>
		<td> <a href="http://www.ebi.ac.uk/chebi/searchId.do;25A6E76925354DCD82F282F5BA968FFE?chebiId=CHEBI:17234"><span class="caps">CHEBI</span>:17234</a></td>
		<td> <a href="http://www.ebi.ac.uk/chebi/">http://www.ebi.ac.uk/chebi/</a> </td>
		<td> urn:miriam:obo.chebi </td>
	</tr>
	<tr>
		<td> Chemical </td>
		<td> <span class="caps">KEGG</span> Compund </td>
		<td> <a href="http://www.genome.jp/dbget-bin/www_bget?cpd:C00031">C0003</a> </td>
		<td> <a href="http://www.genome.jp/kegg/ligand.html">http://www.genome.jp/kegg/ligand.html</a> </td>
		<td> urn:miriam:kegg.compound </td>
	</tr>
	<tr>
		<td> Chemical </td>
		<td> PubChem </td>
		<td> <span class="caps">CID</span>:24749 </td>
		<td> <br>
<a href="http://pubchem.ncbi.nlm.nih.gov/">http://pubchem.ncbi.nlm.nih.gov/</a> </td>
		<td> urn:miriam:pubchem.compound </td>
	</tr>
	<tr>
		<td> Reaction Kinetics </td>
		<td> <span class="caps">SABIO</span>-RK </td>
		<td> 20936 </td>
		<td> <a href="http://sabio.villa-bosch.de/">http://sabio.villa-bosch.de/</a> </td>
		<td> urn:miriam:sabiork.reaction </td>
	</tr>
	<tr>
		<td> Enzymes </td>
		<td> Enzyme Nomenclature (EC) IntEnz </td>
		<td> <a href="http://www.ebi.ac.uk/intenz/query?cmd=SearchEC&amp;ec=1.14.13.39">EC 1.14.13.39</a> </td>
		<td> <a href="http://www.ebi.ac.uk/intenz/">http://www.ebi.ac.uk/intenz/</a> </td>
		<td> urn:miriam:ec-code </td>
	</tr>
	<tr>
		<td> Pathways </td>
		<td> <span class="caps">KEGG</span> Pathways </td>
		<td> <a href="http://www.genome.jp/kegg/pathway/map/map00480.html">map00480</a> </td>
		<td> <a href="http://www.genome.jp/kegg/pathway.html">http://www.genome.jp/kegg/pathway.html</a> </td>
		<td> urn:miriam:kegg.pathway </td>
	</tr>
	<tr>
		<td> Cellular Location </td>
		<td> Gene Ontology </td>
		<td> <a href="http://amigo.geneontology.org/amigo/term/GO:0016020">GO:0016020</a></td>
		<td> <a href="http://www.geneontology.org/">http://www.geneontology.org/</a> </td>
		<td> urn:miriam:obo.go </td>
	</tr>
	<tr>
		<td> Molecular Function </td>
		<td> Gene Ontology </td>
		<td> <a href="http://amigo.geneontology.org/amigo/term/GO:0004857">GO:0004857</a></td>
		<td> <a href="http://www.geneontology.org/">http://www.geneontology.org/</a> </td>
		<td> urn:miriam:obo.go </td>
	</tr>
	<tr>
		<td> Biological Process </td>
		<td> Gene Ontology </td>
		<td> <a href="http://amigo.geneontology.org/amigo/term/GO:0071581">GO:0071581</a></td>
		<td> <a href="http://www.geneontology.org/">http://www.geneontology.org/</a> </td>
		<td> urn:miriam:obo.go </td>
	</tr>
	<tr>
		<td> Literature </td>
		<td> PubMed </td>
		<td> <a href="http://www.ncbi.nlm.nih.gov/pubmed/19112082"><span class="caps">PMID</span>:19112082</a></td>
		<td> <a href="http://www.ncbi.nlm.nih.gov/pubmed/">http://www.ncbi.nlm.nih.gov/pubmed/</a> </td>
		<td> urn:miriam:pubmed </td>
	</tr>
	<tr>
		<td> Model Descriptions </td>
		<td> Systems Biology Ontology </td>
		<td> <a href="http://www.ebi.ac.uk/sbo/main/SBO:0000244"><span class="caps">SBO</span>:0000244</a></td>
		<td> <a href="http://www.ebi.ac.uk/sbo/">http://www.ebi.ac.uk/sbo/</a> </td>
		<td> urn:miriam:biomodels.sbo </td>
	</tr>
</tbody></table>

## Assistance with Data and Models Annotation

Accessing and navigating these resources can be difficult and time-consuming for large data sets. SysMO-DB provide tools to make data and model annotation easier.

### RightField

RightField (http://www.rightfield.org.uk) allows the easy annotation of excel spreadsheet data with terms from community ontologies. Relevant ranges of ontology terms can be embedded into spreadsheets in specific cells as simple drop-down lists. This allows consistent and standards-compliant annotation without the need to browse or navigate the ontologies.   
Multiple ontologies can be used in the same spreadsheet, and the sources of each term and the version of each ontology is automatically collected and recorded.   
A collection of SysMO templates have already been RightField-enabled. These templates are available for download from the templates page and from the SysMO-DB project in the SEEK.

### JWS OneStop

OneStop assists with model annotation and publishing. It is a one-stop-shop for producing a MIRIAM-compliant, annotated model in SBML. OneStop extracts the names used for species and reactions in an uploaded model and uses these names to search public databases for the official terms and MIRIAM identifiers. It uses the Semantic SBML web service (http://semanticsbml.org/) for searching and returns a list of possible matches that the modellers can select from. This ensures the accuracy of each annotation whilst providing an easy mechanism for identifying possible matches.   
In addition to annotations, OneStop also provides editing and validation functionality as well as automatically exporting models in SBGN.  