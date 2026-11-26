float random_value(vec2 position) {
    return fract(
        sin(dot(position, vec2(127.1, 311.7))) * 43758.5453
    );
}