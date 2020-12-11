function T = enhance_morph_clear_border(imgin)
    T = imclearborder(imgin);
    ss = 0.5*std(double(T(T>0)));
    ss = cast(ss,'like',T);
    T = max(0,T-ss);
    % T = imopen(T,ones(2));
end