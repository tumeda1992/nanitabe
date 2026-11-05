export type MutationCallbacks<Output> = {
  onCompleted?: (data: Output) => void;
  onError?: (error: any) => void;
};

export type ExecMutation<Input, Output> = (
  input: Input,
  callbacks: MutationCallbacks<Output>,
) => any;

type BuildMutationOption<Input> = {
  normalizeInput?: (input: Input) => Input;
  refetchQueries?: any[];
};

export const buildMutationExecutor = <Input = any, Output = any>(
  codegenMutationHook: () => any,
  { normalizeInput, refetchQueries }: BuildMutationOption<Input> = {},
) => {
  const [mutation, { mutationLoading, mutationError }] = codegenMutationHook();
  const execMutation = async (
    input: Input,
    { onCompleted, onError }: MutationCallbacks<Output>,
  ) => {
    const normalizedInput = normalizeInput ? normalizeInput(input) : input;
    return mutation({
      variables: normalizedInput,
      refetchQueries,
      onCompleted: (data: Output) => {
        if (onCompleted) onCompleted(data);
      },
      onError: (error: any) => {
        console.error(error);
        if (onError) onError(error);
      },
    });
  };
  return [execMutation, mutationLoading, mutationError];
};
