FROM elixir:1.14

# Set environment variables
ENV MIX_ENV=prod TERM=xterm

# Create app directory and copy project files
WORKDIR /app
COPY . /app

# Install hex package manager and rebar
RUN mix local.hex --force && mix local.rebar --force

# Install dependencies and compile the project
RUN mix deps.get && mix deps.compile && mix compile

# Expose the desired port (4000)
EXPOSE 4000

# Start the server
CMD ["mix", "run", "--no-halt"]