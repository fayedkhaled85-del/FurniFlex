# Furniture text extract

Shopify, *The Catalogue: Product Taxonomy Classification Benchmark* (2025). The publisher designates this dataset Apache-2.0. See the [publisher](https://huggingface.co/datasets/Shopify/product-catalogue), [downloaded source card](SOURCE_CARD.md), and [license](LICENSE-Apache-2.0.txt).

FurniFlex's extraction on November 21, 2026 selected rows whose gold category begins with `Furniture >` in the source train and test shards. The extract contains the title, joined title and description, category path and original split. Merchant images, alternative labels, brand and price are excluded. The 20 source shard paths, Git object names and LFS SHA-256 identifiers are recorded in [source-shards.json](source-shards.json). Reproduction of training uses the local frozen extract. Training and inference require no network connection once Python dependencies are available.

The card reports 1,707 top-level furniture entries. The more specific prefix query returned 1,702 rows. The supplied evidence does not independently establish the categories of the five excluded entries. The full source contains 48,289 products across 10,476 categories.

Frozen furniture.json SHA-256: `82e1f430eb1be5f88db247d1db4236d810bff173d02790b8a7299e7a5d420695`. Customer information was not used. Category mappings and the six training-only class names in the secondary classifier are FurniFlex adaptations. The included product-title text may be multilingual. Intent smoke cases are hand-authored technical checks.
