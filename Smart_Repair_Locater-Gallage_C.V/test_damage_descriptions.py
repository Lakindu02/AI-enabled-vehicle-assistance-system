"""
Test script to demonstrate the enhanced damage detection with descriptions and recommendations
"""

import json
from complete_integration import DamageDetector, Config

def format_damage_report(result):
    """Format the damage detection result into a readable report"""
    if not result:
        return "❌ No damage detection result available"

    report = []
    report.append("\n" + "="*80)
    report.append("🚗 VEHICLE DAMAGE ASSESSMENT REPORT")
    report.append("="*80)

    # Primary Damage Information
    report.append(f"\n📋 PRIMARY DAMAGE DETECTED: {result['damage_type'].upper()}")
    report.append(f"   Confidence: {result['confidence']:.1%}")
    report.append(f"   Severity Score: {result['severity_score']}/5")

    # Additional damages
    if len(result['detected_damages']) > 1:
        report.append(f"\n⚠️  ADDITIONAL DAMAGES DETECTED:")
        for damage in result['detected_damages']:
            if damage != result['damage_type']:
                conf = result['probabilities'][damage]
                report.append(f"   - {damage.capitalize()} (confidence: {conf:.1%})")

    # Damage Details
    details = result['damage_details']

    report.append(f"\n📖 DAMAGE DESCRIPTION:")
    report.append(f"   {details['description']}")

    report.append(f"\n🔍 WHAT HAPPENED:")
    report.append(f"   {details['what_happened']}")

    report.append(f"\n⚡ IMMEDIATE ACTIONS TO TAKE:")
    for i, action in enumerate(details['immediate_actions'], 1):
        report.append(f"   {i}. {action}")

    report.append(f"\n🔧 REPAIR OPTIONS:")
    for i, option in enumerate(details['repair_options'], 1):
        report.append(f"   {i}. {option}")

    report.append(f"\n⏰ URGENCY LEVEL:")
    report.append(f"   {details['urgency']}")

    report.append(f"\n⏱️  ESTIMATED REPAIR TIME:")
    report.append(f"   {details['estimated_time']}")

    report.append(f"\n💡 PREVENTION TIPS:")
    report.append(f"   {details['prevention_tips']}")

    report.append("\n" + "="*80)
    report.append("📞 NEXT STEPS:")
    report.append("   1. Follow the immediate actions listed above")
    report.append("   2. Document the damage with photos from multiple angles")
    report.append("   3. Contact your insurance provider if applicable")
    report.append("   4. Schedule a repair appointment based on urgency level")
    report.append("   5. Use the RoadResQ garage recommendation system for trusted repair shops")
    report.append("="*80 + "\n")

    return "\n".join(report)

def main():
    """Test the damage detector with sample images"""
    print("🚀 Initializing Enhanced Damage Detection System...")

    # Initialize detector
    detector = DamageDetector(Config.DAMAGE_MODEL_PATH)

    # Load model
    if not detector.load_model():
        print("❌ Failed to load damage detection model")
        return

    print("\n✅ Model loaded successfully!")
    print("\n" + "="*80)
    print("📚 DAMAGE TYPES INFORMATION AVAILABLE:")
    print("="*80)

    # Show all damage types and their basic info
    for damage_type in Config.DAMAGE_CLASSES:
        info = detector.get_damage_info(damage_type)
        print(f"\n🔹 {damage_type.upper()}")
        print(f"   Description: {info['description'][:100]}...")
        print(f"   Urgency: {info['urgency']}")
        print(f"   Estimated Time: {info['estimated_time']}")

    print("\n" + "="*80)
    print("\n💡 To test with an actual image, use:")
    print("   result = detector.predict('path/to/your/damage/image.jpg')")
    print("   print(format_damage_report(result))")
    print("\n" + "="*80)

    # Example: Demonstrate with a simulated result
    print("\n📝 EXAMPLE OUTPUT (Simulated 'dent' detection):")
    print("="*80)

    # Simulate a detection result
    simulated_result = {
        'damage_type': 'dent',
        'severity_score': 2,
        'confidence': 0.87,
        'probabilities': {
            'dent': 0.87,
            'scratch': 0.23,
            'crack': 0.15,
            'glass shatter': 0.08,
            'lamp broken': 0.05,
            'tire flat': 0.03
        },
        'detected_damages': ['dent'],
        'damage_details': detector.get_damage_info('dent')
    }

    print(format_damage_report(simulated_result))

if __name__ == "__main__":
    main()
