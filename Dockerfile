FROM python:3.10-slim

# 1. User Setup
RUN useradd -m -u 1000 user
USER user
ENV PATH="/home/user/.local/bin:$PATH"

# 2. Setup Directories
WORKDIR /code

# 3. Copy Code (Sab kuch copy kar lo)
COPY --chown=user . .

# 4. Install Dependencies
# Pehle check karo ki requirements file kahan hai, phir install karo
RUN pip install --no-cache-dir -r NagrikAlert/requirements.txt || pip install --no-cache-dir -r requirements.txt

# 5. WORKDIR Shift (Critical Step)
WORKDIR /code/NagrikAlert

# --- MAGIC FIXES START HERE ---

# Fix A: PYTHONPATH set karein taaki Python ko pata ho root kahan hai
ENV PYTHONPATH=/code/NagrikAlert

# Fix B: __init__.py khud banao (Safety net)
# Agar app folder ke andar ye file nahi hui to import fail hota hai
RUN touch app/__init__.py

# --- MAGIC FIXES END HERE ---

# 6. Expose Port
EXPOSE 7860

# 7. Run Command
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "7860"]