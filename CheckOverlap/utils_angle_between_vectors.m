function theta = utils_angle_between_vectors(v1,v2)
    theta1 = atan2(v1(2),v1(1));
    theta2 = atan2(v2(2),v2(1));
    theta = 180/pi*wrapToPi(theta2-theta1);
end
    