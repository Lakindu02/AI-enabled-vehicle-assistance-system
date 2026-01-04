"""

API Endpoints:
- POST /detect-damage: Upload image and get damage analysis
- POST /recommend-garages: Get garage recommendations
- POST /complete-assessment: Full end-to-end pipeline
- GET /health: Health check
"""

from fastapi import FastAPI, File, UploadFile, HTTPException, Form
from fastapi.responses import JSONResponse, FileResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import List, Optional, Dict
import uvicorn
import os
import shutil
from datetime import datetime
import tempfile

# Import our integration system
from complete_integration import (
    VehicleDamageAssessmentSystem, 
    Config,
    DamageDetector,
    GeminiAnalyzer,
    GoogleMapsService,
    GarageRecommender,
    ReportGenerator
)

# Initialize FastAPI app
app = FastAPI(
    title="RoadResQ API",
    description="Vehicle Damage Assessment & Garage Recommendation System",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify actual origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global system instance
system = None
config = Config()


# Pydantic models for request/response
class LocationModel(BaseModel):
    latitude: float = Field(..., ge=-90, le=90, description="Latitude")
    longitude: float = Field(..., ge=-180, le=180, description="Longitude")


class DamageDetails(BaseModel):
    description: str
    what_happened: str
    immediate_actions: List[str]
    repair_options: List[str]
    urgency: str
    estimated_time: str
    prevention_tips: str


class DamageDetectionResponse(BaseModel):
    damage_type: str
    severity_score: int
    confidence: float
    probabilities: Dict[str, float]
    detected_damages: List[str]
    damage_details: DamageDetails


class GarageRecommendation(BaseModel):
    name: str
    address: str
    rating: float
    total_ratings: int
    latitude: float
    longitude: float
    distance_km: Optional[float]
    distance_text: Optional[str]
    duration_text: Optional[str]
    ml_satisfaction_score: float
    final_score: float
    google_maps_link: str
    place_id: str


class CompletionAssessmentResponse(BaseModel):
    damage_info: DamageDetectionResponse
    gemini_analysis: str
    recommendations: List[GarageRecommendation]
    report_path: str
    timestamp: str


# Startup event
@app.on_event("startup")
async def startup_event():
    """Initialize the system on startup"""
    global system
    
    print("\n" + "="*80)
    print("🚀 STARTING ROADRESQ API SERVER")
    print("="*80 + "\n")
    
    # Initialize system
    system = VehicleDamageAssessmentSystem(config)
    
    # Load models
    if not system.load_models():
        print("❌ Failed to load models!")
    else:
        print("✅ All models loaded successfully!")
    
    print("\n" + "="*80)
    print("✅ API SERVER READY")
    print("="*80 + "\n")


# Shutdown event
@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown"""
    print("\n🛑 Shutting down API server...")


@app.get("/", tags=["Root"])
async def root():
    """Root endpoint"""
    return {
        "message": "Welcome to RoadResQ API",
        "version": "1.0.0",
        "status": "active",
        "endpoints": {
            "health": "/health",
            "docs": "/docs",
            "detect_damage": "POST /detect-damage",
            "recommend_garages": "POST /recommend-garages",
            "complete_assessment": "POST /complete-assessment"
        }
    }


@app.get("/health", tags=["Health"])
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "models_loaded": system is not None,
        "version": "1.0.0"
    }


@app.post("/detect-damage", tags=["Damage Detection"], response_model=DamageDetectionResponse)
async def detect_damage(
    image: UploadFile = File(..., description="Vehicle damage image")
):
    """
    Detect vehicle damage from uploaded image
    
    - **image**: Upload an image file (JPG, PNG)
    
    Returns damage type, severity, and confidence scores
    """
    if system is None:
        raise HTTPException(status_code=503, detail="System not initialized")
    
    # Validate file type
    if not image.content_type.startswith('image/'):
        raise HTTPException(status_code=400, detail="File must be an image")
    
    try:
        # Save uploaded file temporarily
        with tempfile.NamedTemporaryFile(delete=False, suffix='.jpg') as tmp_file:
            shutil.copyfileobj(image.file, tmp_file)
            tmp_path = tmp_file.name
        
        # Detect damage
        damage_info = system.damage_detector.predict(tmp_path)
        
        # Clean up
        os.unlink(tmp_path)
        
        if damage_info is None:
            raise HTTPException(status_code=500, detail="Damage detection failed")
        
        return DamageDetectionResponse(**damage_info)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing image: {str(e)}")


@app.post("/recommend-garages", tags=["Recommendations"], response_model=List[GarageRecommendation])
async def recommend_garages(
    latitude: float = Form(..., ge=-90, le=90),
    longitude: float = Form(..., ge=-180, le=180),
    damage_type: str = Form(..., description="Damage type: minor, moderate, severe"),
    max_results: int = Form(5, ge=1, le=20)
):
    """
    Get garage recommendations based on location and damage type
    
    - **latitude**: User's latitude
    - **longitude**: User's longitude  
    - **damage_type**: Type of damage (minor/moderate/severe)
    - **max_results**: Number of recommendations (default: 5)
    
    Returns list of recommended garages with scores
    """
    if system is None:
        raise HTTPException(status_code=503, detail="System not initialized")
    
    try:
        user_location = (latitude, longitude)
        
        # Validate damage type
        if damage_type not in Config.DAMAGE_CLASSES:
            raise HTTPException(
                status_code=400, 
                detail=f"Invalid damage_type. Must be one of: {Config.DAMAGE_CLASSES}"
            )
        
        # Find nearby garages
        google_garages = system.google_maps.find_nearby_garages(user_location)
        
        if not google_garages:
            raise HTTPException(status_code=404, detail="No garages found nearby")
        
        # Calculate distances
        garage_locations = [(g['latitude'], g['longitude']) for g in google_garages]
        distances = system.google_maps.get_distance_matrix(user_location, garage_locations)
        
        # Add distance info
        for i, garage in enumerate(google_garages):
            if i < len(distances):
                garage['distance_km'] = distances[i]['distance_km']
                garage['distance_text'] = distances[i]['distance_text']
                garage['duration_text'] = distances[i]['duration_text']
        
        # Create damage info for ML model
        damage_info = {
            'damage_type': damage_type,
            'severity_score': Config.DAMAGE_CLASSES.index(damage_type),
            'confidence': 0.85  # Default
        }
        
        # Get recommendations
        recommendations = system.garage_recommender.recommend(
            user_location, damage_info, google_garages, top_k=max_results
        )
        
        # Format response
        response = []
        for rec in recommendations:
            garage = rec['garage']
            response.append(GarageRecommendation(
                name=garage['name'],
                address=garage['address'],
                rating=garage['rating'],
                total_ratings=garage['total_ratings'],
                latitude=garage['latitude'],
                longitude=garage['longitude'],
                distance_km=garage.get('distance_km'),
                distance_text=garage.get('distance_text'),
                duration_text=garage.get('duration_text'),
                ml_satisfaction_score=rec['ml_satisfaction_score'],
                final_score=rec['final_score'],
                google_maps_link=f"https://www.google.com/maps/place/?q=place_id:{garage['place_id']}",
                place_id=garage['place_id']
            ))

        return response
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error generating recommendations: {str(e)}")


@app.post("/complete-assessment", tags=["Complete Pipeline"])
async def complete_assessment(
    image: UploadFile = File(..., description="Vehicle damage image"),
    latitude: float = Form(..., ge=-90, le=90),
    longitude: float = Form(..., ge=-180, le=180)
):
    """
    Complete end-to-end damage assessment pipeline
    
    - **image**: Vehicle damage image
    - **latitude**: User's latitude
    - **longitude**: User's longitude
    
    Returns complete assessment including:
    - Damage detection results
    - Gemini AI analysis
    - Top 5 garage recommendations
    - Downloadable report
    """
    if system is None:
        raise HTTPException(status_code=503, detail="System not initialized")
    
    # Validate file type
    if not image.content_type.startswith('image/'):
        raise HTTPException(status_code=400, detail="File must be an image")
    
    try:
        # Save uploaded file temporarily
        with tempfile.NamedTemporaryFile(delete=False, suffix='.jpg') as tmp_file:
            shutil.copyfileobj(image.file, tmp_file)
            tmp_path = tmp_file.name
        
        user_location = (latitude, longitude)
        
        # Run complete assessment
        results = system.process_damage_image(tmp_path, user_location)
        
        # Clean up temp file
        os.unlink(tmp_path)
        
        if 'error' in results:
            raise HTTPException(status_code=500, detail=results['error'])
        
        # Format recommendations
        formatted_recs = []
        for rec in results['recommendations']:
            garage = rec['garage']
            formatted_recs.append({
                'name': garage['name'],
                'address': garage['address'],
                'rating': garage['rating'],
                'total_ratings': garage['total_ratings'],
                'distance_km': garage.get('distance_km'),
                'distance_text': garage.get('distance_text'),
                'duration_text': garage.get('duration_text'),
                'ml_satisfaction_score': rec['ml_satisfaction_score'],
                'final_score': rec['final_score'],
                'google_maps_link': f"https://www.google.com/maps/place/?q=place_id:{garage['place_id']}",
                'place_id': garage['place_id']
            })
        
        return {
            'damage_info': results['damage_info'],
            'gemini_analysis': results['gemini_analysis'],
            'recommendations': formatted_recs,
            'report_path': results['report_path'],
            'timestamp': datetime.now().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error in complete assessment: {str(e)}")


@app.get("/download-report/{report_filename}", tags=["Reports"])
async def download_report(report_filename: str):
    """
    Download a generated report
    
    - **report_filename**: Name of the report file
    """
    if not os.path.exists(report_filename):
        raise HTTPException(status_code=404, detail="Report not found")
    
    return FileResponse(
        report_filename,
        media_type='text/plain',
        filename=report_filename
    )


# Error handlers
@app.exception_handler(404)
async def not_found_handler(request, exc):
    return JSONResponse(
        status_code=404,
        content={
            "error": "Not Found",
            "message": "The requested resource was not found",
            "path": str(request.url)
        }
    )


@app.exception_handler(500)
async def internal_error_handler(request, exc):
    return JSONResponse(
        status_code=500,
        content={
            "error": "Internal Server Error",
            "message": "An internal error occurred. Please try again later."
        }
    )


# Run the application
if __name__ == "__main__":
    print("\n" + "="*80)
    print("🚀 STARTING ROADRESQ FASTAPI SERVER")
    print("="*80 + "\n")
    print("📚 API Documentation: http://localhost:8000/docs")
    print("📖 ReDoc: http://localhost:8000/redoc")
    print("🏥 Health Check: http://localhost:8000/health")
    print("\n" + "="*80 + "\n")

    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )
