# FurniFlex

FurniFlex is an academic furniture commerce application. Customers can compare six products, configure individual parts in 3D, obtain recommendations and order a configured piece. Separate customer, administrator and manufacturer dashboards support made-to-order work through quotation, production, quality control and simulated delivery.

## Architecture
Apache or the PHP development server runs index.php. The includes directory contains PDO persistence, authentication, pricing, recommendation ranking and production transitions. MariaDB stores catalog definitions, carts, configuration snapshots, quotations, orders and tracking history. The browser uses Bootstrap, JavaScript and local Three.js modules. assets/models and assets/textures supply the geometry and finishes. A separate Python process reads frozen JSON model artifacts from ai-service/artifacts. No Python training job is needed at startup.

## Local installation (Windows PowerShell)
Install Git, PHP 8 with PDO MySQL, mbstring and fileinfo (XAMPP provides these), MariaDB and Python 3.14. Start MariaDB. From a terminal:
~~~powershell
git clone https://github.com/fayedkhaled85-del/FurniFlex.git
cd FurniFlex
# During review, select the publication branch
git switch publication/academic-source-20261123
$env:DB_HOST='127.0.0.1'
$env:DB_PORT='3307'
$env:DB_NAME='furniflex_academic'
$env:DB_USER=Read-Host 'Local MariaDB user'
$env:DB_PASSWORD=[System.Net.NetworkCredential]::new('',(Read-Host 'Database password' -AsSecureString)).Password
$mysql='C:\xampp\mysql\bin\mysql.exe'
& $mysql -h $env:DB_HOST -P $env:DB_PORT -u $env:DB_USER -p -e "CREATE DATABASE furniflex_academic CHARACTER SET utf8mb4"
& $mysql -h $env:DB_HOST -P $env:DB_PORT -u $env:DB_USER -p furniflex_academic -e "source FurniFlex-Schema.sql"
& $mysql -h $env:DB_HOST -P $env:DB_PORT -u $env:DB_USER -p furniflex_academic -e "source database/catalog.sql"
~~~
Initialize only a **new, empty database**. Stop if CREATE DATABASE fails. The schema includes migrations through 023. Historical scripts in database/migrations must not be reapplied to this snapshot. The seed contains catalog and reference data only. Register fresh accounts via the UI. For a local staff demonstration a database administrator can promote dedicated registered accounts by setting users.role to admin or manufacturer for the verified new user ID.

For local development, run the following from the same terminal. Use Apache for hosted deployment because PHP's development server does not enforce .htaccess. The publication includes a development router blocking private directories.
~~~powershell
C:\xampp\php\php.exe -S 127.0.0.1:8080 deploy/local-router.php
~~~
Open http://127.0.0.1:8080/. In a second terminal from the repository root:
~~~powershell
py -3.14 -m venv "$env:LOCALAPPDATA\FurniFlexAdvisor"
$python="$env:LOCALAPPDATA\FurniFlexAdvisor\Scripts\python.exe"
& $python -m pip install -r ai-service/requirements.txt
& $python -B ai-service/serve.py
~~~
Check the inference service with **Invoke-RestMethod http://127.0.0.1:8765/health**. Sign in as a customer and search for “table” with a starting-price budget of $300–500. The classifier guides retrieval; PHP applies availability, dimension and budget rules against the database. Milo Coffee Table is eligible at its starting price. Customization may increase the final price. A prior independently labeled academic ranking experiment reported NDCG@3 of 0.773 versus 0.931 on 17 answerable queries. This measures ranked relevance on that sample; real-customer performance has not been established.

## Docker alternative
With Docker Desktop running Linux containers, from the repository root:
~~~powershell
.\deploy\New-Environment.ps1
docker compose up -d --build
docker compose ps
docker compose logs advisor
~~~
Open http://localhost:8080/. The database initializes schema then catalog on first startup. The app uses the db service on port 3306; PHP reaches the private Advisor service through Compose DNS. Named volumes preserve database, uploads and storage. Use **docker compose stop** between sessions and **docker compose start** to resume. Building requires access to the base images and Python packages.

## Demonstration
1. Customer: Shop → Product Details → Customize. Select a component, adjust its supported dimensions, material or HEX color. Reset View changes the camera. Add the piece to the cart, check out and inspect tracking. PHP validates prices and stores the configuration snapshot.
2. Bespoke furniture: submit a customer request. As Admin, assign it for technical review. As the assigned Manufacturer, submit feasibility feedback. As Admin, issue a quotation. The customer accepts to create the order.
3. Production: Admin assigns a manufacturer, who accepts and completes production. Admin can request rework or approve QC, then record shipping and delivery. The customer confirms receipt.
4. Advisor: try a specific product, a broad request and an impossible budget. Follow recommendations into product details or customization.

## Tests and troubleshooting
Run **C:\xampp\php\php.exe -l index.php**, **node --check assets/js/advisor.js**, and the health check above. Visit the six configurators with product IDs 1, 2, 3, 4, 5 and 8. For database errors check the service port and the environment inherited by PHP. Empty catalog pages usually indicate a missing catalog import. For preview failures check WebGL support and local GLB requests. Advisor outages affect recommendations; check port 8765, pinned Python packages and PHP allow_url_fopen. Give Apache write access to uploads and storage only as needed. Bootstrap presentation may require network access. Payment and shipment events are simulated; the repository contains no real accounts, customer records or mail credentials.

## Design and credits
[Editable FurniFlex design](https://www.figma.com/design/tQubjch63xu9jFgwMgRlMP) · [Home prototype](https://www.figma.com/proto/tQubjch63xu9jFgwMgRlMP/FurniFlex?node-id=6-5656&starting-point-node-id=6%3A5656). Access depends on the Figma file permissions.

Three.js ships with its [MIT notice](assets/js/THREE-LICENSE.txt). [Product visual provenance](assets/images/PRODUCT_VISUAL_SOURCES.md) and [training-data provenance](ai-service/data/NOTICE.md) are included. The full training extract is excluded. The wardrobe is a project asset. The project’s asset evaluation records the following active Innerscene models as CC0:
- <https://www.innerscene.com/tools/library/3d-parts/boxwell-tuxedo-sofa-defac53d>
- <https://www.innerscene.com/tools/library/3d-parts/cove-122-walnut-coffee-table-54d12f31>
- <https://www.innerscene.com/tools/library/3d-parts/linea-140-walnut-writing-desk-c94a30dc>
- <https://www.innerscene.com/tools/library/3d-parts/spindle-spindle-frame-bed-e3b52566>
- <https://www.innerscene.com/tools/library/3d-parts/wingfold-butterfly-leaf-dining-table-114f0a59>
