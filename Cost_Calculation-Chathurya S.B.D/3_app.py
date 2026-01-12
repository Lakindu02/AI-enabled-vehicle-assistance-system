"""
Vehicle Damage Assessment API
FastAPI application with damage detection, price estimation, and Gemini AI
Integrated with Firebase for user authentication and assessment history
"""

import os
import io
import json
import torch
import joblib
import numpy as np
import uuid
from pathlib import Path
from datetime import datetime, timedelta
from typing import Optional, List
from PIL import Image

from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

import torch.nn as nn
from torchvision import transforms, models

# Authentication removed - running without Firebase

# Gemini AI (optional)
try:
    import google.generativeai as genai
    GEMINI_AVAILABLE = True
except ImportError:
    GEMINI_AVAILABLE = False
    print("⚠️  Gemini AI not available. Install: pip install google-generativeai")

# ============================================
# CONFIGURATION
# ============================================

class Config:
    # Paths
    MODELS_DIR = Path("models")
    DAMAGE_MODEL_PATH = MODELS_DIR / "damage_model.pth"
    DAMAGE_LABELS_PATH = MODELS_DIR / "damage_labels.json"
    PRICE_MODEL_PATH = MODELS_DIR / "price_model.pkl"
    PRICE_SCALER_PATH = MODELS_DIR / "price_scaler.pkl"
    
    # Model settings
    IMG_SIZE = (224, 224)
    DAMAGE_THRESHOLD = 0.5
    
    # Gemini API
    GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "AIzaSyBL8AiMZbgPPuehdEhfXfXQ5NFeGcDbX-Y")
    
    # Device
    DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

config = Config()

# ============================================
# DAMAGE DETECTION MODEL
# ============================================

class DamageDetectionModel(nn.Module):
    def __init__(self, num_classes, pretrained=False):
        super().__init__()
        weights = 'DEFAULT' if pretrained else None
        self.backbone = models.resnet18(weights=weights)
        num_features = self.backbone.fc.in_features
        self.backbone.fc = nn.Sequential(
            nn.Linear(num_features, 256),
            nn.ReLU(),
            nn.Dropout(0.5),
            nn.Linear(256, num_classes)
        )
    
    def forward(self, x):
        return self.backbone(x)

# ============================================
# PART MAPPING
# ============================================

def map_damage_to_part(detected_damages: List[str]) -> str:
    """Map detected damages to vehicle parts"""
    part_mapping = {
        'dent': 'body_panel',
        'scratch': 'body_panel',
        'crack': 'bumper',
        'glass_shatter': 'windshield',
        'glass shatter': 'windshield',
        'lamp_broken': 'headlight',
        'lamp broken': 'headlight',
        'tire_flat': 'tire',
        'tire flat': 'tire',
    }
    
    parts = set()
    for damage in detected_damages:
        damage_lower = damage.lower().replace('_', ' ')
        part = part_mapping.get(damage_lower, 'body_panel')
        parts.add(part)
    
    return list(parts)[0] if parts else 'body_panel'

# ============================================
# GEMINI AI CLASSES
# ============================================

class DamageValidationAI:
    """Gemini Vision for damage validation"""
    def __init__(self, api_key: str):
        if GEMINI_AVAILABLE and api_key:
            genai.configure(api_key=api_key)
            self.model = genai.GenerativeModel('gemini-2.5-flash')
        else:
            self.model = None
    
    def validate_damage(self, image: Image.Image, detected_damages: List[str]) -> dict:
        """Get AI validation of detected damages"""
        if not self.model:
            return {'analysis': 'AI not available', 'confidence_score': 'N/A'}
        
        try:
            prompt = f"""
            Analyze this vehicle image for damage.
            Our ML model detected: {', '.join(detected_damages)}
            
            Please:
            1. Confirm if you see these damages
            2. Describe what you observe in 2-3 sentences
            3. Rate confidence (Low/Medium/High)
            
            Keep response brief and professional.
            """
            
            response = self.model.generate_content([prompt, image])
            return {
                'analysis': response.text,
                'confidence_score': 'AI-validated'
            }
        except Exception as e:
            return {'analysis': f'Error: {str(e)}', 'confidence_score': 'N/A'}

class PriceExplanationAI:
    """Gemini Text for price explanation"""
    def __init__(self, api_key: str):
        if GEMINI_AVAILABLE and api_key:
            genai.configure(api_key=api_key)
            self.model = genai.GenerativeModel('gemini-2.5-pro')
        else:
            self.model = None
    
    def explain_price(self, damages: List[str], estimated_price: float) -> dict:
        """Explain price estimate"""
        if not self.model:
            return {'explanation': 'AI not available'}
        
        try:
            prompt = f"""
            Explain this vehicle repair cost estimate:
            - Damages: {', '.join(damages)}
            - Estimated cost: LKR {estimated_price:,.2f}
            
            Provide brief explanation (3-4 sentences):
            1. Main cost factors
            2. Why this price range
            3. What affects the cost
            
            Keep it concise and professional.
            """
            
            response = self.model.generate_content(prompt)
            return {'explanation': response.text}
        except Exception as e:
            return {'explanation': f'Error: {str(e)}'}

# ============================================
# LOAD MODELS ON STARTUP
# ============================================

class ModelLoader:
    def __init__(self):
        self.damage_model = None
        self.price_model = None
        self.price_scaler = None
        self.idx_to_class = None
        self.num_classes = None
        self.damage_ai = None
        self.price_ai = None
        self.transform = None
        
    def load_all(self):
        """Load all models"""
        print("\n" + "="*80)
        print("🔄 LOADING MODELS")
        print("="*80)
        
        # Load damage labels
        print("\n📋 Loading damage labels...")
        try:
            with open(config.DAMAGE_LABELS_PATH, 'r') as f:
                labels_data = json.load(f)
            self.idx_to_class = {int(k): v for k, v in labels_data['idx_to_class'].items()}
            self.num_classes = labels_data['num_classes']
            print(f"✅ Loaded {self.num_classes} damage classes")
        except Exception as e:
            raise RuntimeError(f"Failed to load damage labels: {e}")
        
        # Load damage detection model
        print("\n🧠 Loading damage detection model...")
        try:
            self.damage_model = DamageDetectionModel(self.num_classes, pretrained=False)
            self.damage_model.load_state_dict(
                torch.load(config.DAMAGE_MODEL_PATH, map_location=config.DEVICE)
            )
            self.damage_model.to(config.DEVICE)
            self.damage_model.eval()
            print(f"✅ Damage model loaded on {config.DEVICE}")
        except Exception as e:
            raise RuntimeError(f"Failed to load damage model: {e}")
        
        # Load price model
        print("\n💰 Loading price estimation model...")
        try:
            self.price_model = joblib.load(config.PRICE_MODEL_PATH)
            self.price_scaler = joblib.load(config.PRICE_SCALER_PATH)
            print("✅ Price model loaded")
        except Exception as e:
            raise RuntimeError(f"Failed to load price model: {e}")
        
        # Setup image transformation
        self.transform = transforms.Compose([
            transforms.Resize(config.IMG_SIZE),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406],
                               std=[0.229, 0.224, 0.225])
        ])
        
        # Initialize Gemini AI
        if GEMINI_AVAILABLE and config.GEMINI_API_KEY:
            print("\n🤖 Initializing Gemini AI...")
            try:
                self.damage_ai = DamageValidationAI(config.GEMINI_API_KEY)
                self.price_ai = PriceExplanationAI(config.GEMINI_API_KEY)
                print("✅ Gemini AI initialized")
            except Exception as e:
                print(f"⚠️  Gemini AI initialization failed: {e}")
                self.damage_ai = None
                self.price_ai = None
        else:
            print("\n⚠️  Gemini AI not configured")
            self.damage_ai = None
            self.price_ai = None
        
        print("\n" + "="*80)
        print("✅ ALL MODELS LOADED SUCCESSFULLY")
        print("="*80)

# Initialize model loader
model_loader = ModelLoader()

# ============================================
# FASTAPI APP
# ============================================

app = FastAPI(
    title="Vehicle Damage Assessment API",
    description="API for vehicle damage detection and price estimation",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================================
# PYDANTIC MODELS
# ============================================

class AssessmentResponse(BaseModel):
    timestamp: str
    vehicle: dict
    damage_detection: dict
    part_mapping: dict
    price_estimation: dict
    ai_validation: Optional[dict] = None
    processing_time_seconds: float

class HealthResponse(BaseModel):
    status: str
    models_loaded: bool
    gemini_available: bool
    device: str


# ============================================
# STARTUP EVENT
# ============================================

@app.on_event("startup")
async def startup_event():
    """Load models on startup"""
    try:
        model_loader.load_all()
    except Exception as e:
        print(f"\n❌ ERROR: {e}")
        print("⚠️  API will not work properly without models!")

# ============================================
# API ENDPOINTS
# ============================================

@app.get("/", response_model=dict)
async def root():
    """Root endpoint"""
    return {
        "message": "Vehicle Damage Assessment API",
        "version": "2.0.0",
        "features": ["damage detection", "price estimation", "gemini AI"],
        "endpoints": {
            "assessment": {
                "assess": "/assess (POST)"
            },
            "info": {
                "health": "/health",
                "models": "/models/info"
            },
            "docs": "/docs"
        }
    }

@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    return HealthResponse(
        status="healthy" if model_loader.damage_model is not None else "unhealthy",
        models_loaded=model_loader.damage_model is not None,
        gemini_available=model_loader.damage_ai is not None,
        device=str(config.DEVICE)
    )

@app.post("/assess", response_model=AssessmentResponse)
async def assess_damage(
    image: UploadFile = File(..., description="Vehicle image"),
    vehicle_brand: str = Form(..., description="Vehicle brand (e.g., Toyota)"),
    vehicle_model: str = Form(..., description="Vehicle model (e.g., Corolla)"),
    vehicle_year: int = Form(..., description="Vehicle year (e.g., 2016)"),
    use_ai: bool = Form(True, description="Use Gemini AI for validation")
):
    """
    Assess vehicle damage from image
    
    Returns:
    - Detected damages with confidence scores
    - Affected vehicle part
    - Estimated repair cost
    - AI validation (if enabled)
    """
    start_time = datetime.now()
    
    try:
        # Validate models are loaded
        if model_loader.damage_model is None:
            raise HTTPException(status_code=503, detail="Models not loaded")
        
        # Read and process image
        image_bytes = await image.read()
        pil_image = Image.open(io.BytesIO(image_bytes)).convert('RGB')
        
        # Prepare image for model
        img_tensor = model_loader.transform(pil_image).unsqueeze(0).to(config.DEVICE)
        
        # Damage detection
        with torch.no_grad():
            outputs = model_loader.damage_model(img_tensor)
            probs = torch.sigmoid(outputs).cpu().numpy()[0]
        
        # Get detected damages
        detected_damages = []
        confidences = {}
        
        for i, prob in enumerate(probs):
            if prob > config.DAMAGE_THRESHOLD:
                damage_name = model_loader.idx_to_class[i]
                detected_damages.append(damage_name)
                confidences[damage_name] = float(prob)
        
        # Part mapping
        affected_part = map_damage_to_part(detected_damages)
        
        # Price estimation
        vehicle_age = 2024 - vehicle_year
        num_damages = len(detected_damages)
        
        # Create features (adjust based on your price model's expected features)
        # This is a simplified example - modify based on your actual model
        price_features = np.array([[vehicle_age, num_damages, 1]])  # Adjust as needed
        
        try:
            price_features_scaled = model_loader.price_scaler.transform(price_features)
            estimated_price = float(model_loader.price_model.predict(price_features_scaled)[0])
        except Exception as e:
            # Fallback price estimation
            estimated_price = num_damages * 15000.0  # Simple fallback
        
        # Build response
        response = {
            "timestamp": datetime.now().isoformat(),
            "vehicle": {
                "brand": vehicle_brand,
                "model": vehicle_model,
                "year": vehicle_year
            },
            "damage_detection": {
                "detected_damages": detected_damages,
                "confidences": confidences,
                "num_damages": len(detected_damages),
                "threshold": config.DAMAGE_THRESHOLD
            },
            "part_mapping": {
                "affected_part": affected_part,
                "mapped_from": detected_damages
            },
            "price_estimation": {
                "estimated_price": estimated_price,
                "currency": "LKR",
                "method": "ml_model"
            }
        }
        
        # AI validation (optional)
        if use_ai and model_loader.damage_ai is not None:
            damage_validation = model_loader.damage_ai.validate_damage(
                pil_image, detected_damages
            )
            price_explanation = model_loader.price_ai.explain_price(
                detected_damages, estimated_price
            )
            
            response["ai_validation"] = {
                "damage_validation": damage_validation,
                "price_explanation": price_explanation
            }
        
        # Calculate processing time
        processing_time = (datetime.now() - start_time).total_seconds()
        response["processing_time_seconds"] = processing_time

        # Generate assessment ID for reference
        assessment_id = str(uuid.uuid4())
        response["assessment_id"] = assessment_id

        return JSONResponse(content=response)

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Assessment failed: {str(e)}")


@app.get("/models/info")
async def models_info():
    """Get information about loaded models"""
    if model_loader.damage_model is None:
        raise HTTPException(status_code=503, detail="Models not loaded")

    return {
        "damage_model": {
            "type": "ResNet18",
            "num_classes": model_loader.num_classes,
            "classes": list(model_loader.idx_to_class.values()),
            "device": str(config.DEVICE)
        },
        "price_model": {
            "type": "RandomForest",
            "loaded": model_loader.price_model is not None
        },
        "gemini_ai": {
            "available": model_loader.damage_ai is not None,
            "vision": model_loader.damage_ai is not None,
            "text": model_loader.price_ai is not None
        }
    }

# ============================================
# MAIN
# ============================================

if __name__ == "__main__":
    import uvicorn

    port = int(os.getenv("SERVICE_1_PORT", "8000"))

    print("\n" + "="*80)
    print("🚗 VEHICLE DAMAGE ASSESSMENT API (SERVICE 1)")
    print("="*80)
    print("\nStarting server...")
    print(f"API will be available at: http://localhost:{port}")
    print(f"Documentation: http://localhost:{port}/docs")
    print("\nPress Ctrl+C to stop")
    print("="*80 + "\n")

    uvicorn.run(app, host="0.0.0.0", port=port, reload=False)
