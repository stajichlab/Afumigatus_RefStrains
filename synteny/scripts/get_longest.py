#!/usr/bin/env python3

from Bio import SeqIO
import os
import sys

seqdb = {}
for seq_record in SeqIO.parse(sys.stdin, "fasta"):
    geneid = seq_record.description.split()[0]
    if geneid not in seqdb:
        seqdb[geneid] = seq_record
    elif len(seq_record) > len(seqdb[geneid]):
        seqdb[geneid] = seq_record

SeqIO.write(seqdb.values(),sys.stdout,'fasta')
