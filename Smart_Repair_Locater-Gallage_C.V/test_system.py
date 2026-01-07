"""
Test Script for RoadResQ System


"""

import sys
import os
from complete_integration import VehicleDamageAssessmentSystem, Config

def test_system():
    """Test the complete system with sample data"""
    
    print("\n" + "="*80)
    print("🧪 ROADRESQ SYSTEM TEST")
    print("="*80 + "\n")
    
    # Check API keys
    config = Config()
    
    print("1️⃣ Checking Configuration...")
    if config.GOOGLE_MAPS_API_KEY == 'your_google_maps_api_key_here' or not config.GOOGLE_MAPS_API_KEY:
        print("   ⚠️  Google Maps API key not set")
        print("   Please update Config.GOOGLE_MAPS_API_KEY in complete_integration.py\n")
        return False
    else:
        print("   ✅ Google Maps API key configured\n")

    if config.GEMINI_API_KEY == 'your_gemini_api_key_here' or not config.GEMINI_API_KEY:
        print("   ⚠️  Gemini API key not set")
        print("   Please update Config.GEMINI_API_KEY in complete_integration.py\n")
        return False
    else:
        print("   ✅ Gemini API key configured\n")
    
    # Check model files
    print("2️⃣ Checking Model Files...")
    
    if not os.path.exists(config.DAMAGE_MODEL_PATH):
        print(f"   ❌ Damage model not found: {config.DAMAGE_MODEL_PATH}")
        print("   Please ensure your trained ResNet-18 model is in the correct location\n")
        return False
    else:
        print(f"   ✅ Damage model found: {config.DAMAGE_MODEL_PATH}")
    
    if not os.path.exists(config.GARAGE_MODEL_PATH):
        print(f"   ❌ Garage model not found: {config.GARAGE_MODEL_PATH}")
        print("   Please ensure your trained ML model is in the correct location\n")
        return False
    else:
        print(f"   ✅ Garage model found: {config.GARAGE_MODEL_PATH}")
    
    if not os.path.exists(config.GARAGES_DATA_PATH):
        print(f"   ❌ Garage data not found: {config.GARAGES_DATA_PATH}")
        return False
    else:
        print(f"   ✅ Garage data found: {config.GARAGES_DATA_PATH}\n")
    
    # Initialize system
    print("3️⃣ Initializing System...")
    try:
        system = VehicleDamageAssessmentSystem(config)
        print("   ✅ System initialized\n")
    except Exception as e:
        print(f"   ❌ Error initializing system: {e}\n")
        return False
    
    # Load models
    print("4️⃣ Loading Models...")
    if not system.load_models():
        print("   ❌ Failed to load models\n")
        return False
    print("   ✅ All models loaded successfully\n")
    
    # Test individual components
    print("5️⃣ Testing Individual Components...")
    
    # Test Google Maps
    try:
        print("   Testing Google Maps API...")
        test_location = (6.9271, 79.8612)  # Colombo
        garages = system.google_maps.find_nearby_garages(test_location, radius=5000, max_results=5)
        if garages:
            print(f"   ✅ Google Maps API working ({len(garages)} garages found)")
        else:
            print("   ⚠️  No garages found (check API key or location)")
    except Exception as e:
        print(f"   ❌ Google Maps API error: {e}")
    
    print()
    
    # Summary
    print("="*80)
    print("✅ SYSTEM TEST COMPLETE")
    print("="*80)
    print("\n💡 Next Steps:")
    print("   1. Provide a damage image path")
    print("   2. Run complete assessment:")
    print("      results = system.process_damage_image('image.jpg', (6.9271, 79.8612))")
    print("\n   Or start the FastAPI server:")
    print("      python main.py")
    print("\n" + "="*80 + "\n")
    
    return True


def run_sample_assessment():
    """Run a sample assessment (requires image file)"""
    
    print("\n" + "="*80)
    print("🚗 SAMPLE ASSESSMENT")
    print("="*80 + "\n")
    
    # Get image path from user
    image_path = input("Enter path to damage image (or 'skip' to skip): ").strip()
    
    if image_path.lower() == 'skip':
        print("Skipping sample assessment\n")
        return
    
    if not os.path.exists(image_path):
        print(f"❌ Image not found: {image_path}\n")
        return
    
    # Get location
    print("\nEnter location (or press Enter for default: Colombo)")
    lat = input("Latitude (default: 6.9271): ").strip()
    lon = input("Longitude (default: 79.8612): ").strip()
    
    lat = float(lat) if lat else 6.9271
    lon = float(lon) if lon else 79.8612
    
    user_location = (lat, lon)
    
    # Initialize system
    config = Config()
    system = VehicleDamageAssessmentSystem(config)
    
    if not system.load_models():
        print("❌ Failed to load models\n")
        return
    
    # Run assessment
    print("\n🔄 Running assessment...\n")
    
    try:
        results = system.process_damage_image(image_path, user_location)
        
        if 'error' in results:
            print(f"❌ Error: {results['error']}\n")
            return
        
        # Display results
        print("\n" + "="*80)
        print("📊 ASSESSMENT RESULTS")
        print("="*80)
        
        print(f"\n🔍 Damage Detection:")
        print(f"   Type: {results['damage_info']['damage_type']}")
        print(f"   Confidence: {results['damage_info']['confidence']:.1%}")
        
        print(f"\n🏪 Top Recommendations:")
        for i, rec in enumerate(results['recommendations'][:3], 1):
            garage = rec['garage']
            print(f"   {i}. {garage['name']}")
            print(f"      Rating: {garage['rating']}/5.0")
            print(f"      Distance: {garage.get('distance_text', 'N/A')}")
            print(f"      Score: {rec['final_score']:.1%}")
        
        print(f"\n📄 Full report saved: {results['report_path']}")
        print("\n" + "="*80 + "\n")
        
    except Exception as e:
        print(f"❌ Error during assessment: {e}\n")


def main():
    """Main test menu"""
    
    print("\n" + "="*80)
    print("🚗 ROADRESQ SYSTEM - TEST MENU")
    print("="*80)
    print("\nSelect an option:")
    print("1. Run system test (check configuration and models)")
    print("2. Run sample assessment (with your own image)")
    print("3. Exit")
    print()
    
    choice = input("Enter choice (1-3): ").strip()
    
    if choice == '1':
        test_system()
    elif choice == '2':
        run_sample_assessment()
    elif choice == '3':
        print("\n👋 Goodbye!\n")
        sys.exit(0)
    else:
        print("Invalid choice. Please enter 1, 2, or 3.\n")
        main()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n👋 Test interrupted. Goodbye!\n")
        sys.exit(0)
