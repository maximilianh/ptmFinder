TOOLBIN=maxtools
PUBBIN=pubMunch
get-tools:
	git clone https://github.com/maximilianh/pubMunch.git
	git clone https://github.com/maximilianh/maxtools.git

pull:
	# pull from all three repos
	git pull;
	cd pubMunch; git pull; cd ..
	cd maxtools; git pull; cd ..

get-elm:
	mkdir data
	# phospho ELM dump
	wget http://phospho.elm.eu.org/dumps/phosphoELM_all_latest.dump.tgz -O - | tar xvz
	# uniprot -> organism table, via UCSC -> added to git, no need to download anymore
	# wget http://hgwdev.soe.ucsc.edu/~max/pbeltrao/spOrgs.tar.gz 
	# convert phosphoelm to more reasonable format
	python impPhosphoElm.py > data/pelm.tab

get-text:
	wget http://hgwdev.soe.ucsc.edu/~max/pbeltrao/text.tar.gz -O - | tar xvz

elm-pmidPos:
	# get all PMIDs we have as fulltext
	zcat text/*.articles.gz | cut -f22 | grep -v pmid > gotPmids.txt
	# filter PELM for these PMIDs 
	# make list of pmid-position
	$(TOOLBIN)/lstOp --headers filter data/pelm.tab gotPmids.txt | egrep 'pmid|Homo' | $(TOOLBIN)/tabCut -n pmid,pos | sort -u | tr '\t' '-' > data/pmidPos.pelm.txt
	@echo number of pmid-pos tuples:
	@wc -l data/pmidPos.pelm.txt
	# extract pmid-gene tuples
	$(TOOLBIN)/lstOp --headers filter data/pelm.tab gotPmids.txt | egrep 'pmid|Homo' | $(TOOLBIN)/tabCut -n pmid,spId | sort -u > data/pmidProt.pelm.txt
	@echo number of pmid-gene tuples:
	@wc -l data/pmidProt.pelm.txt

test-search:
	$(PUBBIN)/pubRunAnnot phospho text data/pred --cat --test

search-phospho:
	$(PUBBIN)/pubRunAnnot phospho text data/pred -c localhost:7 --cat
	# extract pmid-position tuples from search results
	$(TOOLBIN)/tabCut -n pmid,position data/pred.tab | tr '\t' '-' | sort -u > data/pmidPos.pred.txt

search-genes:
	# search for genes on localhost with 7 threads
	$(PUBBIN)/pubRunAnnot geneSearch text data/genes -c localhost:7 --cat

recall-pmidPos:
	@echo total number of pmid-pos tuples to find:
	@wc -l data/pmidPos.pelm.txt
	@echo total number of pmid-pos tuples found:
	@$(TOOLBIN)/lstIntersect data/pmidPos.pred.txt data/pmidPos.pelm.txt | wc -l

missed-pmidPos:
	# show the pmidPos-tuples that were missed by the position finder
	lstOp remove data/pmidPos.pelm.txt data/pmidPos.pred.txt | less

#  create a table with PMID-gene, use the best 100 genes per paper
best-genes-100:
	cat data/genes.tab | gawk '($$7<=100)' | cut -f5,10 > data/bestGenes.tab

#  create a table with PMID-gene, use the best 10 genes per paper
best-genes-10:
	cat data/genes.tab | gawk '($$7<=10)' | cut -f5,10 > data/bestGenes.tab

# benchmark PELM genes against our genes (10 or 100)
bench-genes:
	$(TOOLBIN)/hashBenchmark data/bestGenes.tab data/pmidProt.pelm.txt
	
# 
# simple graphs

hist-genesPerPaper:
	less data/pmidProt.pelm.txt | grep -v pmid | cut -f1 | $(TOOLBIN)/tabUniq -s | cut -f2 | textHistogram stdin stdout -binSize=1

hist-genesPerPaper:
	less data/bestGenes.tab | cut -f1 | $(TOOLBIN)/tabUniq -s | cut -f2 |  textHistogram stdin stdout -binSize=10

