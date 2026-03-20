# Start with a machine that has Julia 1.10 installed
FROM julia:1.10

# Create a folder inside the container for our project
WORKDIR /app

# Copy dependency list first (for Docker layer caching)
COPY Project.toml .

# Install all Julia dependencies
RUN julia --project=. -e 'using Pkg; Pkg.instantiate()'

# Copy the rest of our project files
COPY . .

# When someone runs the container, run the simulation
CMD ["julia", "--project=.", "-e", "using TiltedBBL; run_simulation(\"configs/default.toml\")"]
