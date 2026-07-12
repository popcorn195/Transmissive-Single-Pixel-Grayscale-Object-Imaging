import torch


def total_variation(img):
    diff_h = img[:, :, :, 1:] - img[:, :, :, :-1]
    diff_v = img[:, :, 1:, :] - img[:, :, :-1, :]
    return (
        torch.mean(torch.abs(diff_h))
        + torch.mean(torch.abs(diff_v))
    )


def physics_loss(Q_measured, O_hat, H, alpha=1e-4):
    O_flat = O_hat.reshape(-1)
    Q_predicted = H @ O_flat

    # measurement consistency
    data_term = torch.mean((Q_measured - Q_predicted) ** 2)

    # image smoothness prior
    tv_term = total_variation(O_hat)

    loss = data_term + alpha * tv_term
    return loss