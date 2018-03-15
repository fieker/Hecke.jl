Qx, x = FlintQQ["x"]
K1, a1 = NumberField(x^6 - x^5 + x^4 - x^3 + x^2 - x + 1, "a") # totally complex
K2, a2 = NumberField(x^6 - x^5 - 7*x^4 + 2*x^3 + 7*x^2 - 2*x - 1, "a") # totally real
K3, a3 = NumberField(x^6 - x^5 - x^4 + 4*x^3 + 3*x^2 - 1, "a") # signature (2, 2)

@testset "Totally real/complex" begin
  @test @inferred istotally_complex(K1)
  @test @inferred !istotally_complex(K2)
  @test @inferred !istotally_complex(K3)

  @test @inferred !istotally_real(K1)
  @test @inferred istotally_real(K2)
  @test @inferred !istotally_real(K3)
end

@testset "conjugates_arb" begin
  CC = AcbField(64)

  co = @inferred conjugates(10001 * a1 + 1, 256)

  @test overlaps(co[1], CC("[9011.589647892093681 +/- 9.30e-16]", "[4339.271274914698763 +/- 9.19e-16]"))
  @test Hecke.radiuslttwopower(co[1], -256)
  @test overlaps(co[2], CC("[-6234.521508389194039 +/- 8.09e-16]", "[7819.096656162766117 +/- 5.63e-16]"))
  @test Hecke.radiuslttwopower(co[2], -256)
  @test overlaps(co[3], CC("[2226.431860497100357 +/- 4.55e-16]", "[9750.25404973041789 +/- 4.36e-15]"))
  @test Hecke.radiuslttwopower(co[3], -256)
  @test overlaps(co[4], CC("[9011.589647892093681 +/- 9.30e-16]", "[-4339.271274914698763 +/- 9.19e-16]"))
  @test Hecke.radiuslttwopower(co[4], -256)
  @test overlaps(co[5], CC("[-6234.521508389194039 +/- 8.09e-16]", "[-7819.096656162766117 +/- 5.63e-16]"))
  @test Hecke.radiuslttwopower(co[5], -256)
  @test overlaps(co[6], CC("[2226.431860497100357 +/- 4.55e-16]", "[-9750.25404973041789 +/- 4.36e-15]"))
  @test Hecke.radiuslttwopower(co[6], -256)

  RR = ArbField(64)

  co = @inferred conjugates_real(a3, 32)
  @test length(co) == 2

  @test Hecke.radiuslttwopower(co[1], -32)
  @test Hecke.overlaps(co[1], RR("[-1.221417721 +/- 5.71e-10]"))
  @test Hecke.radiuslttwopower(co[2], -32)
  @test Hecke.overlaps(co[2], RR("[0.4665 +/- 4.52e-5]"))

  co = @inferred conjugates_complex(a3, 32)
  @test length(co) == 2
  @test Hecke.radiuslttwopower(co[1], -32)
  @test Hecke.overlaps(co[1], CC("[-0.542287022 +/- 3.58e-10]", "[0.460349889 +/- 4.60e-10]" ))
  @test Hecke.radiuslttwopower(co[2], -32)
  @test Hecke.overlaps(co[2], CC("[1.419725855 +/- 5.85e-10]", "[1.205211655 +/- 7.03e-10]"))

  colog = @inferred conjugates_log(a1, 16)
  @test length(colog) == 3
  @test contains(colog[1], 0)
  @test contains(colog[2], 0)
  @test contains(colog[3], 0)

  mink = @inferred minkowski_map(a3, 32)
  @test length(mink) == 6
  co = conjugates(a3, 32)
  sqrt2 = sqrt(RR(2))
  @test overlaps(mink[1], real(co[1]))
  @test overlaps(mink[2], real(co[2]))
  @test overlaps(mink[3], sqrt2 * real(co[3]))
  @test overlaps(mink[4], sqrt2 * imag(co[3]))
  @test overlaps(mink[5], sqrt2 * real(co[4]))
  @test overlaps(mink[6], sqrt2 * imag(co[4]))
end

