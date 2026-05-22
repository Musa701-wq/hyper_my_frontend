import pymongo
from pymongo import MongoClient

# Source MongoDB (Remote)
SOURCE_URI = "mongodb://bubblenexus:BN123XyZ456@13.62.97.219:27017/bubblenexus?authSource=bubblenexus"
# Target MongoDB (Local)
TARGET_URI = "mongodb://localhost:27017"

def migrate_icons():
    try:
        # Connect to source
        source_client = MongoClient(SOURCE_URI)
        source_db = source_client.get_database()
        source_collection = source_db['hip-3'] 

        # Connect to target
        target_client = MongoClient(TARGET_URI)
        target_db = target_client['bubblenexus'] 
        target_collection = target_db['hip-3']

        print(f"Connecting to source: {SOURCE_URI.split('@')[-1]}")
        tickers = list(source_collection.find({}, {"symbol": 1, "iconUrl": 1}))
        print(f"Found {len(tickers)} tickers in source.")

        updated_count = 0
        for ticker in tickers:
            symbol = ticker.get('symbol')
            icon_url = ticker.get('iconUrl')
            
            if symbol and icon_url:
                result = target_collection.update_one(
                    {"symbol": symbol},
                    {"$set": {"iconUrl": icon_url}}
                )
                if result.modified_count > 0:
                    updated_count += 1
                    print(f"Updated icon for {symbol}")

        print(f"\nMigration Complete!")
        print(f"Total processed: {len(tickers)}")
        print(f"Total icons updated: {updated_count}")

    except Exception as e:
        print(f"Error during migration: {e}")
    finally:
        source_client.close()
        target_client.close()

if __name__ == "__main__":
    migrate_icons()
