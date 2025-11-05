function clamp(value, min, max)
    return math.max(math.min(value, max), min)
end

function infinite_approach(at_zero, at_infinite, x_halfway, x)
    return (at_infinite - (at_infinite-at_zero)*0.5^(x/x_halfway)) + 0.001
end
