
function ts = QAM(tbit, modulation)

    tm = qammod(tbit.',modulation,'InputType','bit');
    ts = tm.';

end

