using Godot;
using System;
using MathNet.Numerics.Distributions; // Import MathNet for distributions.
using Accord.Statistics.Distributions; // Import Accord.NET for distributions.

public partial class Distributions : Node
{
	// Method to calculate the inverse of the cumulative distribution function for a normal distribution.
	public double InverseNormalCDF(double mean, double standardDeviation, double probability)
	{
		// Clamp the probability to avoid extreme values at the tails.
		double clampedProbability = Math.Clamp(probability, double.Epsilon, 1 - double.Epsilon);
		
		// Create a normal distribution with the given mean and standard deviation.
		Normal normalDistribution = new Normal(mean, standardDeviation);
		
		// Calculate the inverse CDF (quantile) for the clamped probability.
		return normalDistribution.InverseCumulativeDistribution(clampedProbability);
	}
	
	// Method to calculate the inverse of the CDF for an exponential distribution.
	public double InverseExponentialCDF(double rate, double probability)
	{
		// Clamp the probability to avoid extreme values.
		double clampedProbability = Math.Clamp(probability, double.Epsilon, 1 - double.Epsilon);

		// Create an exponential distribution with the given rate parameter.
		Exponential exponentialDistribution = new Exponential(rate);

		// Calculate the inverse CDF (quantile) for the clamped probability.
		return exponentialDistribution.InverseCumulativeDistribution(clampedProbability);
	}
	
	// Method to calculate the inverse of the CDF for a geometric distribution starting at n.
	public int InverseGeometricCDF(double successProbability, double probability, int startAtN)
	{
		// Clamp the probability to avoid extreme values.
		double clampedProbability = Math.Clamp(probability, double.Epsilon, 1 - double.Epsilon);
		
		// Calculate the inverse CDF (quantile) for the clamped probability.
		return (int)Math.Ceiling(Math.Log(1 - clampedProbability) / Math.Log(1 - successProbability)) + (startAtN - 1);
	}

	// Method to calculate the inverse of the CDF for a Poisson distribution.
	public int InversePoissonCDF(double lambda, double probability)
	{
		// Clamp the probability to avoid extreme values.
		double clampedProbability = Math.Clamp(probability, double.Epsilon, 1 - double.Epsilon);

		// Create a Poisson distribution with the given mean parameter (lambda).
		Poisson poissonDistribution = new Poisson(lambda);

		// Set an initial upper bound as lambda * 5, which should cover most cases.
		int initialUpperBound = (int)Math.Ceiling(lambda * 5);
		int result = BinarySearchPoissonCDF(poissonDistribution, clampedProbability, 0, initialUpperBound);

		// If the result is equal to the initial upper bound, it may indicate that the upper bound was insufficient.
		// Increase the upper bound and search again if needed.
		while (poissonDistribution.CumulativeDistribution(result) < clampedProbability)
		{
			// Double the upper bound and search again until we find a sufficient upper bound.
			initialUpperBound *= 2;
			result = BinarySearchPoissonCDF(poissonDistribution, clampedProbability, 0, initialUpperBound);
		}

		return result;
	}
	
	// Custom binary search method for finding the smallest k where the Poisson CDF meets or exceeds the target probability.
	// This method efficiently finds the quantile value (inverse CDF) for the Poisson distribution using binary search.
	private int BinarySearchPoissonCDF(Poisson poissonDistribution, double targetProbability, int lowerBound, int upperBound)
	{
		// The loop continues until the search range is narrowed down to a single value.
		while (lowerBound < upperBound)
		{
			// Calculate the midpoint of the current range to split the search space in half.
			// Using this form of calculation to avoid potential overflow issues.
			int mid = lowerBound + (upperBound - lowerBound) / 2;

			// If the CDF value at 'mid' is less than the target probability, it means the target must be in the upper half.
			// Therefore, shift the lower bound to 'mid + 1' to continue the search in the upper half.
			if (poissonDistribution.CumulativeDistribution(mid) < targetProbability)
			{
				lowerBound = mid + 1;
			}
			// Otherwise, the CDF value at 'mid' is greater than or equal to the target.
			// This means the target is in the lower half, so we shift the upper bound to 'mid' to search there.
			else
			{
				upperBound = mid;
			}
		}

		// When the loop exits, 'lowerBound' will be the smallest integer k such that the CDF(k) >= targetProbability.
		return lowerBound;
	}
	
	// Method to calculate the inverse of the CDF for a discrete distribution.
	public string InverseDiscreteCDF(string[] values, double[] probabilities, double probability)
	{
		// Clamp the probability to be between 0 and 1 to avoid out-of-bounds errors.
		double clampedProbability = Math.Clamp(probability, 0.0, 1.0);

		// Calculate the cumulative distribution (CDF) array based on probabilities.
		double[] cdf = new double[probabilities.Length + 1];
		cdf[0] = 0.0;  // Start the CDF at zero.

		for (int i = 0; i < probabilities.Length; i++)
		{
			cdf[i + 1] = cdf[i] + probabilities[i];
		}

		// Find the index where the cumulative probability matches or exceeds the given probability.
		int index = Array.FindIndex(cdf, p => p >= clampedProbability);

		// Ensure the index is within the bounds of the values array.
		// Since `cdf` has one extra element (starting at 0), we use `values[index - 1]` when `index > 0`.
		if (index <= 0)
		{
			// If the index is 0 or less (shouldn't happen with a well-formed CDF), return the first value.
			return values[0];
		}
		else if (index >= cdf.Length)
		{
			// If the index is beyond the last CDF value, return the last value.
			return values[values.Length - 1];
		}

		// Return the corresponding value from the `values` array.
		return values[index - 1];
	}
	
	// Method to calculate the inverse of the CDF for a binomial distribution.
	public int InverseBinomialCDF(int trials, double successProbability, double probability)
	{
		// Clamp the probability to avoid extreme values (edge cases).
		double clampedProbability = Math.Clamp(probability, double.Epsilon, 1 - double.Epsilon);

		// Create a binomial distribution with the given number of trials and probability of success.
		Binomial binomialDistribution = new Binomial(successProbability, trials);

		// Set an initial uSpper bound as trials, which is the maximum possible value for the binomial distribution.
		int initialUpperBound = trials;
		int result = BinarySearchBinomialCDF(binomialDistribution, clampedProbability, 0, initialUpperBound);

		return result;
	}

	// Custom binary search method for finding the smallest k where the Binomial CDF meets or exceeds the target probability.
	private int BinarySearchBinomialCDF(Binomial binomialDistribution, double targetProbability, int lowerBound, int upperBound)
	{
		// The loop continues until the search range is narrowed down to a single value.
		while (lowerBound < upperBound)
		{
			// Calculate the midpoint of the current range to split the search space in half.
			int mid = lowerBound + (upperBound - lowerBound) / 2;

			// If the CDF value at 'mid' is less than the target probability, shift the lower bound to 'mid + 1' to search the upper half.
			if (binomialDistribution.CumulativeDistribution(mid) < targetProbability)
			{
				lowerBound = mid + 1;
			}
			// Otherwise, shift the upper bound to 'mid' to search the lower half.
			else
			{
				upperBound = mid;
			}
		}

		// When the loop exits, 'lowerBound' will be the smallest integer k such that the CDF(k) >= targetProbability.
		return lowerBound;
	}
	
	// Method to calculate the inverse of the CDF for a truncated normal distribution.
	public double InverseTruncatedNormalCDF(double mean, double standardDeviation, double probability, double lowerBound, double upperBound)
	{
		// Ensure the bounds make sense (lower bound should be less than upper bound).
		if (lowerBound >= upperBound)
		{
			throw new ArgumentException("Lower bound must be less than upper bound.");
		}

		// Standardize bounds relative to a standard normal (mean 0, standard deviation 1).
		double standardizedLower = (lowerBound - mean) / standardDeviation;
		double standardizedUpper = (upperBound - mean) / standardDeviation;

		// Calculate cumulative probabilities at the standardized bounds.
		double cdfLower = Normal.CDF(0, 1, standardizedLower);
		double cdfUpper = Normal.CDF(0, 1, standardizedUpper);

		// Adjust probability to fit within the truncated range [cdfLower, cdfUpper].
		// Scale `probability` so that it maps to [cdfLower, cdfUpper].
		double adjustedProbability = cdfLower + probability * (cdfUpper - cdfLower);

		// Calculate the inverse CDF for the adjusted probability.
		double standardizedResult = Normal.InvCDF(0, 1, adjustedProbability);

		// Transform the result back to the original mean and standard deviation.
		return mean + standardizedResult * standardDeviation;
	}
	
	// Method to calculate the inverse of the CDF for a truncated exponential distribution.
	public double InverseTruncatedExponentialCDF(double rate, double probability, double lowerBound, double upperBound)
	{
		// Ensure the bounds make sense (lower bound should be less than upper bound).
		if (lowerBound >= upperBound)
		{
			throw new ArgumentException("Lower bound must be less than upper bound.");
		}
		
		// Clamp the probability to avoid extreme values.
		double clampedProbability = Math.Clamp(probability, double.Epsilon, 1 - double.Epsilon);

		// Create an exponential distribution with the given rate parameter.
		Exponential exponentialDistribution = new Exponential(rate);

		// Calculate the CDF values at the bounds.
		double cdfLower = exponentialDistribution.CumulativeDistribution(lowerBound);
		double cdfUpper = exponentialDistribution.CumulativeDistribution(upperBound);

		// Scale the probability to fit within the truncated range.
		double adjustedProbability = cdfLower + clampedProbability * (cdfUpper - cdfLower);

		// Calculate the inverse CDF for the adjusted probability within the truncated range.
		return exponentialDistribution.InverseCumulativeDistribution(adjustedProbability);
	}

}
