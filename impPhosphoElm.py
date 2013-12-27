import logging, gzip

def slurpdict(fname):
    """ read in tab delimited file as dict key -> value (integer) """
    dict = {}
    for l in gzip.open(fname, "r"):
        l = l.strip("\n")
        fs = l.split("\t")
	if not len(fs)>1:
            continue
        key = fs[0]
        val = fs[1]
        if key not in dict:
            dict[key] = val
        else:
            sys.stderr.write("info: hit key %s two times: %s -> %s\n" %(key, key, val))
    return dict

def main():
    spToOrg = slurpdict("spOrgs.tab.gz")

    headers = ["spId", "org", "pos", "pmid", "kinase", "expType"]
    print "\t".join(headers)

    skipCount = 0
    notFoundCount = 0
    count = 0
    noPmidCount = 0
    for line in open("phosphoELM_all_2011-11.dump"):
        if line.startswith("acc"):
            continue
        fields = line.split("\t")
        pos = fields[2]
        pmids = fields[4].split(";")
        kinases = fields[5]
        expTypes = fields[6].split(";")
        acc = fields[0]
        for i in range(len(pmids)):
            if expTypes[i] == "HTP":
                continue
            if acc.startswith("ENSP"):
                skipCount +=1
                continue
            if pmids[i]=="N.N." or pmids[i]=="":
                noPmidCount +=1
                continue
            mainAcc = acc.split("-")[0]
            if mainAcc not in spToOrg:
                notFoundCount +=1 
                continue
            org = spToOrg[mainAcc]
            row = [ acc, org, pos, pmids[i], kinases, expTypes[i]]
            print "\t".join(row)
            count += 1

    logging.warn("skipped %d with ensembl id" % skipCount)
    logging.warn("skipped %d with unknown uniprot ids" % notFoundCount)
    logging.warn("skipped %d with invalid pmids" % noPmidCount)
    logging.warn("converted %d sites " % count)

main()
