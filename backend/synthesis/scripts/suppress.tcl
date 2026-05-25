# Disable assertions for the first 30 ns (during reset)
assertion -off
run 30ns

# Re-enable assertions for the rest of the simulation
assertion -on
run