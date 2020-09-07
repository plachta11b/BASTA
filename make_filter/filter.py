import timeit
import gffutils
import os.path as path

ensembl = '/code/Homo_sapiens.GRCh38.100.gff3'
gencode_small = '/code/gencode.v34.chr_patch_hapl_scaff.annotation.small.gff3'

source_file = gencode_small

fn = gffutils.example_filename(source_file)
database_filename = source_file + '.sqlite3'

if not path.isfile(database_filename):
    db = gffutils.create_db(fn, database_filename,
                            merge_strategy='create_unique')

    raw_db = db.conn.cursor()

    raw_db.execute(
        '''create table genes_to_id (id text, gene_id text, gene_subid text)''')

    genes_list = []
    for row in db.all_features():
        if 'gene_id' in row.attributes:
            v_gene_id, v_gene_subid = row.attributes["gene_id"][0].split(".")
            v_id = row.id
            genes_list.append((v_id, v_gene_id, v_gene_subid))

    raw_db.executemany('INSERT INTO genes_to_id VALUES (?,?,?)', genes_list)
    db.conn.commit()


else:
    db = gffutils.FeatureDB(database_filename)
    raw_db = db.conn.cursor()

with open("./genes_many") as file:
    genes = [line.rstrip('\n') for line in file]


def find():
    total = 0

    ids = []

    for gene in genes:
        # cur = db.execute(
        #     "SELECT featuretype,attributes FROM features "
        #     "WHERE featuretype='five_prime_UTR' AND attributes LIKE '%{}.%';".format(gene))

        cur = raw_db.execute(
            "SELECT * FROM genes_to_id WHERE gene_id=?", (gene,))

        for row in cur.fetchall():
            ids.append(row["id"])

    for row in ids:
        print(db[row])


time = timeit.timeit(find, number=1)

# docker run -it -v $(realpath .):/code quay.io/biocontainers/gffutils:0.10.1--py_0
