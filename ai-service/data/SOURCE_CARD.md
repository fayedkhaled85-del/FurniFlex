---
license: apache-2.0
task_categories:
  - image-classification
  - text-classification
  - zero-shot-classification
tags:
  - e-commerce
  - product-categorization
  - taxonomy
  - multimodal
  - shopify
  - retail
  - product-catalog
size_categories:
  - 10K<n<100K
dataset_info:
  features:
  - name: product_title
    dtype: string
  - name: product_description
    dtype: string
  - name: product_image
    dtype: image
  - name: potential_product_categories
    list: string
  - name: ground_truth_brand
    dtype: string
  - name: ground_truth_is_secondhand
    dtype: bool
  - name: ground_truth_category
    dtype: string
  splits:
  - name: train
    num_bytes: 7425492387
    num_examples: 38631
  - name: test
    num_bytes: 2085920280
    num_examples: 9658
  download_size: 9496974081
  dataset_size: 9511412667
configs:
- config_name: default
  data_files:
  - split: train
    path: data/train-*
  - split: test
    path: data/test-*
---

# The Catalogue: Product Taxonomy Classification Benchmark

A large-scale, multimodal benchmark dataset for product taxonomy classification, featuring real e-commerce products with images, descriptions, and hierarchical category labels.

## Dataset Description

**The Catalogue** is a benchmark dataset designed to evaluate AI models on the task of classifying products into a standardized taxonomy. Each sample includes a product image, title, description, brand, and the ground-truth category from Shopify's product taxonomy.

This dataset is ideal for:
- Evaluating vision-language models on real-world product classification
- Benchmarking multimodal understanding in e-commerce contexts
- Testing hierarchical classification capabilities
- Comparing different approaches to product categorization

### Dataset Statistics

| Metric | Value |
|--------|-------|
| Total samples | 48,289 |
| Unique categories | 10,476 |
| Unique brands | 28,913 |
| Products with descriptions | 92.9% |
| Products with brand | 98.2% |
| Average category depth | 4.5 levels |
| Category depth range | 1-8 levels |

### Top-Level Category Distribution

| Category | Count | Percentage |
|----------|-------|------------|
| Home & Garden | 7,912 | 16.4% |
| Sporting Goods | 6,968 | 14.4% |
| Arts & Entertainment | 5,558 | 11.5% |
| Hardware | 5,137 | 10.6% |
| Vehicles & Parts | 2,555 | 5.3% |
| Business & Industrial | 2,435 | 5.0% |
| Electronics | 2,344 | 4.9% |
| Apparel & Accessories | 2,173 | 4.5% |
| Health & Beauty | 2,162 | 4.5% |
| Food, Beverages & Tobacco | 2,036 | 4.2% |
| Animals & Pet Supplies | 1,922 | 4.0% |
| Furniture | 1,707 | 3.5% |
| Baby & Toddler | 1,226 | 2.5% |
| Toys & Games | 1,153 | 2.4% |
| Office Supplies | 1,129 | 2.3% |
| Cameras & Optics | 967 | 2.0% |
| Other | 900 | 1.9% |

## Dataset Structure

### Data Fields

| Field | Type | Description |
|-------|------|-------------|
| `product_title` | string | Product title |
| `product_description` | string | Product description (may be empty) |
| `product_image` | Image | Product image |
| `potential_product_categories` | list[string] | Candidate category paths |
| `ground_truth_brand` | string | Brand name (may be empty) |
| `ground_truth_is_secondhand` | boolean | Whether the product is secondhand |
| `ground_truth_category` | string | Ground truth category path |

### Category Format

Categories follow a hierarchical path format:
```
Electronics > Computers > Laptops
Home & Garden > Kitchen & Dining > Cookware
```

### Data Splits

| Split | Samples | Percentage |
|-------|---------|------------|
| Train | 38,631 | 80% |
| Test | 9,658 | 20% |

## Usage

```python
from datasets import load_dataset

dataset = load_dataset("Shopify/product-catalogue")

# Access splits
train_data = dataset["train"]
test_data = dataset["test"]

# Example
sample = train_data[0]
print(f"Title: {sample['product_title']}")
print(f"Category: {sample['ground_truth_category']}")
sample['product_image'].show()
```

## Evaluation

The primary task is to predict the `ground_truth_category` given the product's image, title, and optionally description/brand.

Suggested metrics:
- Hierarchical F1 for categories
- Precision and recall for brand and is_secondhand

## Source

Products were sampled from Shopify's merchant catalog, representing real e-commerce products across diverse categories and industries.

## License

Apache 2.0

## Citation

```bibtex
@dataset{product-catalogue,
  title={The Catalogue: Product Taxonomy Classification Benchmark},
  author={Shopify},
  year={2025},
  publisher={Hugging Face},
  url={https://huggingface.co/datasets/Shopify/the-catalogue-public-beta}
}
```

